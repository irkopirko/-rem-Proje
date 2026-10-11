import { WebSocketServer } from 'ws';
import { query } from '../db.js';
import { verifyAccessToken } from '../utils/jwt.js';
import { avatarFrame, isBlockedMembership, isStaff } from './membership.js';
import { quietEvaluate } from './badges.js';

export const MAX_MESSAGE_LENGTH = 2000;
const AUTH_TIMEOUT_MS = 10_000;
const HEARTBEAT_MS = 30_000;
const RATE_WINDOW_MS = 10_000;
const RATE_MAX_MESSAGES = 8;
/** userId → Set<WebSocket>. Single-instance hub; add Redis pub/sub before scaling to >1 replica. */
const sockets = new Map();

export function canJoin(user) {
  if (!user || user.deleted_at) return false;
  return !isBlockedMembership(user);
}

export function messageDTO(row) {
  const staff = isStaff(row);
  return {
    id: String(row.id),
    userId: row.user_id,
    username: row.username ?? null,
    displayName: staff ? 'Ink Akademi Crew' : row.username ? `@${row.username}` : row.first_name,
    role: row.role,
    photoUrl: row.profile_photo_url ?? null,
    frame: avatarFrame(row),
    xp: Number(row.xp || 0),
    body: row.body,
    createdAt: new Date(row.created_at).toISOString(),
  };
}

const MESSAGE_SELECT = `SELECT cm.id, cm.user_id, cm.body, cm.created_at, u.username, u.first_name, u.role, u.membership_status, u.profile_photo_url, u.xp
  FROM community_messages cm JOIN users u ON u.id = cm.user_id`;

export async function loadMessage(id) {
  const [row] = await query(`${MESSAGE_SELECT} WHERE cm.id = ? AND cm.deleted_at IS NULL`, [id]);
  return row ? messageDTO(row) : null;
}

export async function loadHistory({ viewerId, before, limit }) {
  const params = [viewerId];
  let cursor = '';
  if (before) {
    cursor = 'AND cm.id < ?';
    params.push(before);
  }
  params.push(limit);
  const rows = await query(
    `${MESSAGE_SELECT}
     WHERE cm.deleted_at IS NULL
       AND cm.user_id NOT IN (SELECT blocked_id FROM user_blocks WHERE blocker_id = ?)
       ${cursor}
     ORDER BY cm.id DESC LIMIT ?`,
    params.map((p) => (typeof p === 'number' ? String(p) : p))
  );
  return rows.reverse().map(messageDTO);
}

function send(ws, payload) {
  if (ws.readyState === ws.OPEN) ws.send(JSON.stringify(payload));
}

export function broadcast(payload) {
  const data = JSON.stringify(payload);
  for (const set of sockets.values()) {
    for (const ws of set) if (ws.readyState === ws.OPEN) ws.send(data);
  }
}

export function notifyUser(userId, payload) {
  for (const ws of sockets.get(userId) ?? []) send(ws, payload);
}

export function onlineCount() {
  return sockets.size;
}

function track(ws, userId) {
  if (!sockets.has(userId)) sockets.set(userId, new Set());
  sockets.get(userId).add(ws);
  ws.on('close', () => {
    const set = sockets.get(userId);
    if (!set) return;
    set.delete(ws);
    if (!set.size) sockets.delete(userId);
  });
}

async function loadUser(id) {
  const [user] = await query(
    `SELECT id, role, username, first_name, membership_status, chat_banned, deleted_at FROM users WHERE id = ? LIMIT 1`,
    [id]
  );
  return user;
}

async function handleSend(ws, payload) {
  const body = typeof payload.body === 'string' ? payload.body.trim() : '';
  const clientMessageId = typeof payload.clientMessageId === 'string' ? payload.clientMessageId.slice(0, 64) : null;
  if (!body || body.length > MAX_MESSAGE_LENGTH) {
    return send(ws, { type: 'error', code: 'invalid', clientMessageId });
  }

  const now = Date.now();
  ws.sentAt = (ws.sentAt ?? []).filter((t) => now - t < RATE_WINDOW_MS);
  if (ws.sentAt.length >= RATE_MAX_MESSAGES) {
    return send(ws, { type: 'error', code: 'rate_limited', clientMessageId });
  }
  ws.sentAt.push(now);

  // Re-read so bans and membership changes apply immediately.
  const user = await loadUser(ws.userId);
  if (!canJoin(user)) {
    send(ws, { type: 'error', code: 'forbidden', clientMessageId });
    return ws.close(4003, 'forbidden');
  }
  if (user.chat_banned && user.role === 'student') {
    return send(ws, { type: 'error', code: 'banned', clientMessageId });
  }

  const result = await query(`INSERT INTO community_messages (user_id, body) VALUES (?, ?)`, [user.id, body]);
  const message = await loadMessage(result.insertId);
  broadcast({ type: 'message', message, clientMessageId });
  quietEvaluate(user.id);
}

export function attachCommunitySocket(server) {
  const wss = new WebSocketServer({ noServer: true, maxPayload: 16 * 1024 });

  server.on('upgrade', (req, socket, head) => {
    const { pathname } = new URL(req.url, 'http://localhost');
    if (pathname !== '/ws/community') return socket.destroy();
    wss.handleUpgrade(req, socket, head, (ws) => wss.emit('connection', ws, req));
  });

  wss.on('connection', (ws) => {
    ws.isAlive = true;
    ws.on('pong', () => {
      ws.isAlive = true;
    });

    const authTimer = setTimeout(() => {
      if (!ws.userId) ws.close(4001, 'auth timeout');
    }, AUTH_TIMEOUT_MS);

    ws.on('message', async (raw) => {
      let payload;
      try {
        payload = JSON.parse(raw.toString());
      } catch {
        return send(ws, { type: 'error', code: 'invalid' });
      }

      try {
        if (!ws.userId) {
          if (payload.type !== 'auth') return ws.close(4001, 'auth required');
          const claims = verifyAccessToken(String(payload.token || ''));
          const user = await loadUser(claims.sub);
          if (!canJoin(user)) return ws.close(4003, 'forbidden');
          clearTimeout(authTimer);
          ws.userId = user.id;
          track(ws, user.id);
          const blocks = await query(`SELECT blocked_id AS id FROM user_blocks WHERE blocker_id = ?`, [user.id]);
          return send(ws, {
            type: 'ready',
            userId: user.id,
            canSend: !(user.chat_banned && user.role === 'student'),
            blockedUserIds: blocks.map((b) => b.id),
            maxLength: MAX_MESSAGE_LENGTH,
          });
        }

        if (payload.type === 'send') return await handleSend(ws, payload);
        if (payload.type === 'ping') return send(ws, { type: 'pong' });
      } catch (err) {
        if (!ws.userId) return ws.close(4001, 'invalid token');
        console.error('[community]', err.message);
        send(ws, { type: 'error', code: 'server' });
      }
    });

    ws.on('close', () => clearTimeout(authTimer));
  });

  const heartbeat = setInterval(() => {
    for (const ws of wss.clients) {
      if (!ws.isAlive) {
        ws.terminate();
        continue;
      }
      ws.isAlive = false;
      ws.ping();
    }
  }, HEARTBEAT_MS);
  wss.on('close', () => clearInterval(heartbeat));

  return wss;
}
