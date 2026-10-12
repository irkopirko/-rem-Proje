import { v4 as uuidv4 } from 'uuid';
import { query, withTransaction } from '../db.js';
import { deleteFromStorage, isStorageConfigured, storageCdnUrl, uploadToStorage } from './bunny.js';
import { detectImageMime } from './contentImages.js';
import { avatarFrame, isStaff } from './membership.js';
import { canJoin } from './community.js';
import { currentXp, grantXpOnce, XP_FEED_LIKE, XP_FEED_REPLY } from './badges.js';
import { publicLevel } from './levels.js';

export const MAX_POST_LENGTH = 2000;
export const MAX_REPLY_LENGTH = 500;
export const MAX_MEDIA_PER_POST = 4;
export const MAX_FEED_IMAGE_BYTES = 5 * 1024 * 1024;
export const MAX_FEED_VIDEO_BYTES = 40 * 1024 * 1024;

const POSTS_PER_HOUR = 8;
const REPLIES_PER_HOUR = 20;
const LIKES_PER_MINUTE = 60;

export function canUseFeed(user) {
  return canJoin(user);
}

export function canWriteFeed(user) {
  return canUseFeed(user) && !user?.chat_banned;
}

function authorDTO(row) {
  const staff = isStaff(row);
  return {
    userId: row.user_id || row.id,
    username: row.username ?? null,
    displayName: staff ? 'Ink Akademi Crew' : row.username ? `@${row.username}` : row.first_name,
    firstName: row.first_name ?? null,
    role: row.role,
    photoUrl: row.profile_photo_url ?? null,
    frame: avatarFrame(row),
    ...publicLevel(row.xp, staff),
  };
}

export function feedMediaPublicUrl(id, storageKey) {
  return (storageKey && storageCdnUrl(storageKey)) || `/media/feed-media/${id}`;
}

function mediaDTO(row) {
  return {
    id: row.id,
    kind: row.kind,
    mimeType: row.mime_type,
    url: feedMediaPublicUrl(row.id, row.storage_key || row.storageKey),
  };
}

function postDTO(row, media, viewer) {
  return {
    id: row.id,
    body: row.body,
    createdAt: new Date(row.created_at).toISOString(),
    updatedAt: new Date(row.updated_at).toISOString(),
    author: authorDTO(row),
    media: (media || []).filter(Boolean),
    likeCount: Number(row.likeCount || 0),
    replyCount: Number(row.replyCount || 0),
    liked: Boolean(row.liked),
    canDelete: Boolean(viewer && (row.user_id === viewer.id || isStaff(viewer))),
  };
}

function replyDTO(row, media = []) {
  return {
    id: row.id,
    postId: row.post_id,
    parentReplyId: row.parent_reply_id ?? null,
    body: row.body,
    createdAt: new Date(row.created_at).toISOString(),
    author: authorDTO(row),
    media: (media || []).filter(Boolean),
    canDelete: Boolean(row.canDelete),
  };
}

function blockClause(alias = 'fp') {
  return `${alias}.user_id NOT IN (SELECT blocked_id FROM user_blocks WHERE blocker_id = ?)
     AND ${alias}.user_id NOT IN (SELECT blocker_id FROM user_blocks WHERE blocked_id = ?)`;
}

const POST_SELECT = `SELECT fp.id, fp.body, fp.created_at, fp.updated_at, fp.user_id,
    u.username, u.first_name, u.role, u.membership_status, u.profile_photo_url, u.xp,
    (SELECT COUNT(*) FROM feed_likes fl WHERE fl.post_id = fp.id) AS likeCount,
    (SELECT COUNT(*) FROM feed_replies fr WHERE fr.post_id = fp.id AND fr.deleted_at IS NULL) AS replyCount,
    EXISTS(SELECT 1 FROM feed_likes fl WHERE fl.post_id = fp.id AND fl.user_id = ?) AS liked`;

async function attachMedia(posts) {
  if (!posts.length) return posts;
  const ids = posts.map((p) => p.id);
  const placeholders = ids.map(() => '?').join(',');
  const rows = await query(
    `SELECT id, post_id AS postId, kind, mime_type, storage_key FROM feed_media
     WHERE post_id IN (${placeholders}) AND reply_id IS NULL ORDER BY sort_order, created_at`,
    ids
  );
  const map = {};
  for (const row of rows) {
    (map[row.postId] ??= []).push(mediaDTO(row));
  }
  return posts.map((post) => ({ ...post, media: map[post.id] ?? [] }));
}

function parseCursor(raw) {
  if (!raw) return null;
  const [time, id] = String(raw).split('|');
  if (!time || !id) return null;
  const date = new Date(time);
  if (Number.isNaN(date.getTime())) return null;
  return { time: date, id };
}

export async function listPosts(viewer, { cursor, limit = 20 } = {}) {
  const take = Math.min(Math.max(Number(limit) || 20, 1), 50);
  const parsed = parseCursor(cursor);
  const params = [viewer.id, viewer.id, viewer.id];
  let extra = '';
  if (parsed) {
    extra = ` AND (fp.created_at < ? OR (fp.created_at = ? AND fp.id < ?))`;
    params.push(parsed.time, parsed.time, parsed.id);
  }
  const rows = await query(
    `${POST_SELECT}
     FROM feed_posts fp
     JOIN users u ON u.id = fp.user_id
     WHERE fp.deleted_at IS NULL AND ${blockClause('fp')} ${extra}
     ORDER BY fp.created_at DESC, fp.id DESC
     LIMIT ${take}`,
    params
  );
  const withMedia = await attachMedia(rows);
  const last = rows[rows.length - 1];
  return {
    posts: withMedia.map((row) => postDTO(row, row.media, viewer)),
    nextCursor: rows.length === take && last ? `${new Date(last.created_at).toISOString()}|${last.id}` : null,
  };
}

export async function latestPost(viewer) {
  const { posts } = await listPosts(viewer, { limit: 1 });
  return posts[0] ?? null;
}

async function loadPostRow(postId, viewerId) {
  const [row] = await query(
    `${POST_SELECT}
     FROM feed_posts fp
     JOIN users u ON u.id = fp.user_id
     WHERE fp.id = ? AND fp.deleted_at IS NULL
     LIMIT 1`,
    [viewerId, postId]
  );
  return row ?? null;
}

export async function getPostForViewer(viewer, postId) {
  const row = await loadPostRow(postId, viewer.id);
  if (!row) return null;
  const [hydrated] = await attachMedia([row]);
  return postDTO(row, hydrated.media, viewer);
}

async function attachReplyMedia(replies) {
  if (!replies.length) return replies;
  const ids = replies.map((r) => r.id);
  const placeholders = ids.map(() => '?').join(',');
  const rows = await query(
    `SELECT id, reply_id AS replyId, kind, mime_type, storage_key FROM feed_media
     WHERE reply_id IN (${placeholders}) ORDER BY sort_order, created_at`,
    ids
  );
  const map = {};
  for (const row of rows) {
    (map[row.replyId] ??= []).push(mediaDTO(row));
  }
  return replies.map((reply) => ({ ...reply, media: map[reply.id] ?? [] }));
}

export async function listReplies(viewer, postId) {
  const rows = await query(
    `SELECT fr.id, fr.post_id, fr.parent_reply_id, fr.body, fr.created_at, fr.user_id,
            u.username, u.first_name, u.role, u.membership_status, u.profile_photo_url, u.xp
     FROM feed_replies fr
     JOIN users u ON u.id = fr.user_id
     WHERE fr.post_id = ? AND fr.deleted_at IS NULL
     ORDER BY fr.created_at ASC, fr.id ASC
     LIMIT 200`,
    [postId]
  );
  const withMedia = await attachReplyMedia(rows);
  return withMedia.map((row) => ({
    ...replyDTO(row, row.media),
    canDelete: row.user_id === viewer.id || isStaff(viewer),
  }));
}

export async function readFeedMedia(id) {
  const [row] = await query(
    `SELECT id, kind, mime_type AS mimeType, storage_key AS storageKey, data FROM feed_media WHERE id = ? LIMIT 1`,
    [id]
  );
  if (!row) return null;
  if (row.storageKey) {
    return { mimeType: row.mimeType, data: row.data, storageKey: row.storageKey };
  }
  if (row.data) return { mimeType: row.mimeType, data: row.data, storageKey: null };
  return null;
}

async function countRecent(table, userId, minutes, extra = '') {
  const [row] = await query(
    `SELECT COUNT(*) AS n FROM ${table} WHERE user_id = ? AND created_at >= (UTC_TIMESTAMP() - INTERVAL ? MINUTE) ${extra}`,
    [userId, minutes]
  );
  return Number(row?.n || 0);
}

function normalizeBody(text, max) {
  const body = String(text || '').replace(/\s+/g, ' ').trim();
  if (body.length > max) return { error: 'Metin çok uzun' };
  return { body };
}

function isLowQuality(body) {
  const compact = body.replace(/\s/g, '');
  if (compact.length >= 8) {
    const unique = new Set(compact.toLowerCase());
    if (unique.size < 3) return true;
  }
  return false;
}

export async function createPost(user, { body, clientRequestId }) {
  if (!canWriteFeed(user)) return { status: 402, body: { error: 'Membership required' } };
  const parsed = normalizeBody(body, MAX_POST_LENGTH);
  if (parsed.error) return { status: 400, body: { error: parsed.error } };
  if (clientRequestId) {
    const [existing] = await query(
      `SELECT id FROM feed_posts WHERE user_id = ? AND client_request_id = ? LIMIT 1`,
      [user.id, clientRequestId]
    );
    if (existing) {
      const post = await getPostForViewer(user, existing.id);
      return { status: 200, body: { post, xpAwarded: 0, totalXp: await currentXp(user.id) } };
    }
  }
  if ((await countRecent('feed_posts', user.id, 60, 'AND deleted_at IS NULL')) >= POSTS_PER_HOUR) {
    return { status: 429, body: { error: 'Çok sık paylaşım yapıyorsun. Biraz sonra dene.' } };
  }
  const id = uuidv4();
  await query(`INSERT INTO feed_posts (id, user_id, body, client_request_id) VALUES (?, ?, ?, ?)`, [
    id,
    user.id,
    parsed.body,
    clientRequestId || null,
  ]);
  return { status: 201, body: { post: await getPostForViewer(user, id), xpAwarded: 0, totalXp: await currentXp(user.id) } };
}

function detectVideoMime(buffer) {
  if (!Buffer.isBuffer(buffer) || buffer.length < 12) return null;
  const head = buffer.subarray(0, 64).toString('latin1');
  if (head.includes('ftyp')) return 'video/mp4';
  const box = buffer.subarray(4, 8).toString('ascii');
  if (box === 'moov' || box === 'mdat' || box === 'wide' || box === 'skip' || box === 'free') {
    return 'video/mp4';
  }
  return null;
}

export async function addPostMedia(user, postId, buffer) {
  if (!canWriteFeed(user)) return { status: 402, body: { error: 'Membership required' } };
  const [post] = await query(`SELECT id, user_id FROM feed_posts WHERE id = ? AND deleted_at IS NULL LIMIT 1`, [postId]);
  if (!post) return { status: 404, body: { error: 'Not found' } };
  if (post.user_id !== user.id) return { status: 403, body: { error: 'Forbidden' } };

  const imageMime = detectImageMime(buffer);
  const videoMime = detectVideoMime(buffer);
  if (!imageMime && !videoMime) return { status: 415, body: { error: 'Sadece JPEG, PNG, WebP veya MP4 yükleyebilirsin.' } };
  const kind = imageMime ? 'image' : 'video';
  const mimeType = imageMime || videoMime;
  const maxBytes = kind === 'image' ? MAX_FEED_IMAGE_BYTES : MAX_FEED_VIDEO_BYTES;
  if (buffer.length > maxBytes) return { status: 413, body: { error: 'Dosya çok büyük' } };

  const [{ count, maxOrder, videos }] = await query(
    `SELECT COUNT(*) AS count, COALESCE(MAX(sort_order), -1) AS maxOrder,
            SUM(kind = 'video') AS videos
     FROM feed_media WHERE post_id = ? AND reply_id IS NULL`,
    [postId]
  );
  if (count >= MAX_MEDIA_PER_POST) return { status: 409, body: { error: 'En fazla 4 medya ekleyebilirsin' } };
  if (kind === 'video' && Number(videos) > 0) return { status: 409, body: { error: 'Gönderiye bir video ekleyebilirsin' } };

  const stored = await storeFeedMedia({ postId, replyId: null, buffer, kind, mimeType, userId: user.id, maxOrder });
  return { status: stored.status, body: stored.body };
}

async function storeFeedMedia({ postId, replyId, buffer, kind, mimeType, userId, maxOrder }) {
  const id = uuidv4();
  const ext = kind === 'video' ? 'mp4' : mimeType === 'image/png' ? 'png' : mimeType === 'image/webp' ? 'webp' : 'jpg';
  let storageKey = null;
  if (isStorageConfigured()) {
    storageKey = `feed-media/${replyId || postId}/${id}.${ext}`;
    try {
      await uploadToStorage(storageKey, buffer, mimeType);
    } catch (err) {
      console.error('[feed] storage upload failed', err.message);
      storageKey = null;
    }
  }
  const data = kind === 'image' ? buffer : null;
  if (!storageKey && !data) return { status: 503, body: { error: 'Medya şu an yüklenemedi' } };
  await query(
    `INSERT INTO feed_media (id, post_id, reply_id, kind, mime_type, byte_size, storage_key, data, sort_order, uploaded_by_user_id)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [id, postId, replyId, kind, mimeType, buffer.length, storageKey, data, Number(maxOrder) + 1, userId]
  );
  return { status: 201, body: { media: mediaDTO({ id, kind, mime_type: mimeType }) } };
}

export async function addReplyMedia(user, replyId, buffer) {
  if (!canWriteFeed(user)) return { status: 402, body: { error: 'Membership required' } };
  const [reply] = await query(
    `SELECT id, post_id, user_id FROM feed_replies WHERE id = ? AND deleted_at IS NULL LIMIT 1`,
    [replyId]
  );
  if (!reply) return { status: 404, body: { error: 'Not found' } };
  if (reply.user_id !== user.id) return { status: 403, body: { error: 'Forbidden' } };

  const imageMime = detectImageMime(buffer);
  if (!imageMime) return { status: 415, body: { error: 'Yanıta yalnızca JPEG, PNG veya WebP ekleyebilirsin.' } };
  if (buffer.length > MAX_FEED_IMAGE_BYTES) return { status: 413, body: { error: 'Dosya çok büyük' } };

  const [{ count, maxOrder }] = await query(
    `SELECT COUNT(*) AS count, COALESCE(MAX(sort_order), -1) AS maxOrder FROM feed_media WHERE reply_id = ?`,
    [replyId]
  );
  if (count >= 1) return { status: 409, body: { error: 'Yanıta bir görsel ekleyebilirsin' } };

  return storeFeedMedia({
    postId: reply.post_id,
    replyId,
    buffer,
    kind: 'image',
    mimeType: imageMime,
    userId: user.id,
    maxOrder,
  });
}

export async function deletePost(user, postId) {
  const [row] = await query(`SELECT id, user_id FROM feed_posts WHERE id = ? AND deleted_at IS NULL LIMIT 1`, [postId]);
  if (!row) return { status: 404, body: { error: 'Not found' } };
  if (row.user_id !== user.id && !isStaff(user)) return { status: 403, body: { error: 'Forbidden' } };
  await query(`UPDATE feed_posts SET deleted_at = UTC_TIMESTAMP(), deleted_by_user_id = ? WHERE id = ?`, [user.id, row.id]);
  return { status: 200, body: { ok: true } };
}

export async function toggleLike(user, postId) {
  if (!canWriteFeed(user)) return { status: 402, body: { error: 'Membership required' } };
  if ((await countRecent('feed_likes', user.id, 1)) >= LIKES_PER_MINUTE) {
    return { status: 429, body: { error: 'Çok hızlı beğeniyorsun.' } };
  }
  const result = await withTransaction(async (exec) => {
    const [post] = await exec(`SELECT id, user_id FROM feed_posts WHERE id = ? AND deleted_at IS NULL LIMIT 1`, [postId]);
    if (!post) return { status: 404, body: { error: 'Not found' } };
    const [existing] = await exec(`SELECT 1 AS ok FROM feed_likes WHERE user_id = ? AND post_id = ? LIMIT 1`, [
      user.id,
      postId,
    ]);
    if (existing) {
      await exec(`DELETE FROM feed_likes WHERE user_id = ? AND post_id = ?`, [user.id, postId]);
      return { liked: false, xp: { awarded: false, amount: 0 } };
    }
    await exec(`INSERT INTO feed_likes (user_id, post_id) VALUES (?, ?)`, [user.id, postId]);
    let xp = { awarded: false, amount: 0 };
    if (post.user_id !== user.id) {
      xp = await grantXpOnce(user.id, `feed_like:${user.id}:${postId}`, XP_FEED_LIKE, exec);
    }
    return { liked: true, xp };
  });
  if (result.status) return result;
  const [counts] = await query(`SELECT COUNT(*) AS n FROM feed_likes WHERE post_id = ?`, [postId]);
  return {
    status: 200,
    body: {
      liked: result.liked,
      likeCount: Number(counts?.n || 0),
      xpAwarded: result.xp.awarded ? result.xp.amount : 0,
      totalXp: await currentXp(user.id),
    },
  };
}

export async function createReply(user, postId, { body, parentReplyId, clientRequestId, hasMedia }) {
  if (!canWriteFeed(user)) return { status: 402, body: { error: 'Membership required' } };
  const parsed = normalizeBody(body, MAX_REPLY_LENGTH);
  if (parsed.error) return { status: 400, body: { error: parsed.error } };
  if (!parsed.body && !hasMedia) return { status: 400, body: { error: 'Yanıt boş' } };
  if (parsed.body && parsed.body.length < 2) return { status: 400, body: { error: 'Yanıt çok kısa' } };
  if (parsed.body && isLowQuality(parsed.body)) return { status: 400, body: { error: 'Bu yanıt yayınlanamadı' } };

  if (clientRequestId) {
    const [existing] = await query(
      `SELECT id FROM feed_replies WHERE user_id = ? AND client_request_id = ? LIMIT 1`,
      [user.id, clientRequestId]
    );
    if (existing) {
      const [row] = await query(
        `SELECT fr.id, fr.post_id, fr.parent_reply_id, fr.body, fr.created_at, fr.user_id,
                u.username, u.first_name, u.role, u.membership_status, u.profile_photo_url, u.xp
         FROM feed_replies fr JOIN users u ON u.id = fr.user_id WHERE fr.id = ?`,
        [existing.id]
      );
      const [hydrated] = await attachReplyMedia([row]);
      return {
        status: 200,
        body: { reply: { ...replyDTO(hydrated, hydrated.media), canDelete: true }, xpAwarded: 0, totalXp: await currentXp(user.id) },
      };
    }
  }

  const [post] = await query(`SELECT id FROM feed_posts WHERE id = ? AND deleted_at IS NULL LIMIT 1`, [postId]);
  if (!post) return { status: 404, body: { error: 'Not found' } };
  if (parentReplyId) {
    const [parent] = await query(
      `SELECT id FROM feed_replies WHERE id = ? AND post_id = ? AND deleted_at IS NULL LIMIT 1`,
      [parentReplyId, postId]
    );
    if (!parent) return { status: 404, body: { error: 'Not found' } };
  }
  if ((await countRecent('feed_replies', user.id, 60, 'AND deleted_at IS NULL')) >= REPLIES_PER_HOUR) {
    return { status: 429, body: { error: 'Çok sık yanıt yazıyorsun. Biraz sonra dene.' } };
  }
  if (parsed.body) {
    const [dup] = await query(
      `SELECT id FROM feed_replies
       WHERE user_id = ? AND post_id = ? AND body = ? AND created_at >= (UTC_TIMESTAMP() - INTERVAL 2 MINUTE)
       LIMIT 1`,
      [user.id, postId, parsed.body]
    );
    if (dup) return { status: 409, body: { error: 'Aynı yanıtı az önce gönderdin' } };
  }

  const id = uuidv4();
  const xp = await withTransaction(async (exec) => {
    await exec(
      `INSERT INTO feed_replies (id, post_id, parent_reply_id, user_id, body, client_request_id)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [id, postId, parentReplyId || null, user.id, parsed.body, clientRequestId || null]
    );
    return grantXpOnce(user.id, `feed_reply:${id}`, XP_FEED_REPLY, exec);
  });
  const [row] = await query(
    `SELECT fr.id, fr.post_id, fr.parent_reply_id, fr.body, fr.created_at, fr.user_id,
            u.username, u.first_name, u.role, u.membership_status, u.profile_photo_url, u.xp
     FROM feed_replies fr JOIN users u ON u.id = fr.user_id WHERE fr.id = ?`,
    [id]
  );
  return {
    status: 201,
    body: {
      reply: { ...replyDTO(row, []), canDelete: true },
      xpAwarded: xp.awarded ? xp.amount : 0,
      totalXp: await currentXp(user.id),
    },
  };
}

export async function deleteReply(user, replyId) {
  const [row] = await query(`SELECT id, user_id FROM feed_replies WHERE id = ? AND deleted_at IS NULL LIMIT 1`, [replyId]);
  if (!row) return { status: 404, body: { error: 'Not found' } };
  if (row.user_id !== user.id && !isStaff(user)) return { status: 403, body: { error: 'Forbidden' } };
  await query(`UPDATE feed_replies SET deleted_at = UTC_TIMESTAMP(), deleted_by_user_id = ? WHERE id = ?`, [
    user.id,
    row.id,
  ]);
  return { status: 200, body: { ok: true } };
}

export async function reportPost(user, postId, reason) {
  const [post] = await query(`SELECT id, user_id FROM feed_posts WHERE id = ? LIMIT 1`, [postId]);
  if (!post) return { status: 404, body: { error: 'Not found' } };
  if (post.user_id === user.id) return { status: 400, body: { error: 'Kendi gönderini bildiremezsin' } };
  await query(`INSERT IGNORE INTO feed_reports (id, post_id, reporter_id, reason) VALUES (?, ?, ?, ?)`, [
    uuidv4(),
    postId,
    user.id,
    reason || null,
  ]);
  return { status: 200, body: { ok: true } };
}

export async function reportReply(user, replyId, reason) {
  const [reply] = await query(`SELECT id, user_id FROM feed_replies WHERE id = ? LIMIT 1`, [replyId]);
  if (!reply) return { status: 404, body: { error: 'Not found' } };
  if (reply.user_id === user.id) return { status: 400, body: { error: 'Kendi yanıtını bildiremezsin' } };
  await query(`INSERT IGNORE INTO feed_reports (id, reply_id, reporter_id, reason) VALUES (?, ?, ?, ?)`, [
    uuidv4(),
    replyId,
    user.id,
    reason || null,
  ]);
  return { status: 200, body: { ok: true } };
}

export async function publicAuthor(userId) {
  const [row] = await query(
     `SELECT id, id AS user_id, username, first_name, last_name, role, membership_status, profile_photo_url, xp
     FROM users WHERE id = ? AND deleted_at IS NULL LIMIT 1`,
    [userId]
  );
  if (!row) return null;
  return authorDTO(row);
}

/** Soft-deleted media files stay on CDN; called when a post is hard-removed later if needed. */
export async function deleteMediaFiles(postId) {
  const rows = await query(`SELECT storage_key AS storageKey FROM feed_media WHERE post_id = ? AND storage_key IS NOT NULL`, [
    postId,
  ]);
  await Promise.all(rows.map((r) => deleteFromStorage(r.storageKey)));
}
