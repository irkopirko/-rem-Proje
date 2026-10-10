import { Router } from 'express';
import { z } from 'zod';
import { v4 as uuidv4 } from 'uuid';
import { query } from '../db.js';
import { requireAuth, requireCrew } from '../middleware/auth.js';
import { auditLog } from '../services/audit.js';
import { broadcast, canJoin, loadHistory, notifyUser, onlineCount } from '../services/community.js';

const router = Router();
router.use(requireAuth);

const isStaff = (user) => user.role === 'crew' || user.role === 'super_admin';

router.use((req, res, next) => {
  if (!canJoin(req.user)) return res.status(402).json({ error: 'Membership required' });
  next();
});

router.get('/messages', async (req, res) => {
  const before = req.query.before ? Number(req.query.before) : null;
  if (before !== null && (!Number.isSafeInteger(before) || before <= 0)) {
    return res.status(400).json({ error: 'Invalid input' });
  }
  const limit = Math.min(Math.max(Number(req.query.limit) || 50, 1), 100);
  const messages = await loadHistory({ viewerId: req.user.id, before, limit });
  return res.json({ messages, hasMore: messages.length === limit, online: onlineCount() });
});

router.delete('/messages/:id', async (req, res) => {
  const [row] = await query(`SELECT id, user_id FROM community_messages WHERE id = ? AND deleted_at IS NULL`, [
    req.params.id,
  ]);
  if (!row) return res.status(404).json({ error: 'Not found' });
  if (row.user_id !== req.user.id && !isStaff(req.user)) return res.status(403).json({ error: 'Forbidden' });

  await query(`UPDATE community_messages SET deleted_at = UTC_TIMESTAMP(), deleted_by_user_id = ? WHERE id = ?`, [
    req.user.id,
    row.id,
  ]);
  if (row.user_id !== req.user.id) {
    await auditLog({ actorUserId: req.user.id, action: 'community.message_delete', targetType: 'community_message', targetId: String(row.id), metadata: { author: row.user_id }, ip: req.ip });
  }
  broadcast({ type: 'deleted', id: String(row.id) });
  return res.json({ ok: true });
});

router.post('/messages/:id/report', async (req, res) => {
  const parsed = z.object({ reason: z.string().trim().max(500).optional() }).safeParse(req.body ?? {});
  if (!parsed.success) return res.status(400).json({ error: 'Invalid input' });
  const [row] = await query(`SELECT id, user_id FROM community_messages WHERE id = ?`, [req.params.id]);
  if (!row) return res.status(404).json({ error: 'Not found' });
  if (row.user_id === req.user.id) return res.status(400).json({ error: 'Cannot report own message' });
  await query(
    `INSERT IGNORE INTO community_reports (id, message_id, reporter_id, reason) VALUES (?, ?, ?, ?)`,
    [uuidv4(), row.id, req.user.id, parsed.data.reason ?? null]
  );
  return res.json({ ok: true });
});

router.get('/blocks', async (req, res) => {
  const rows = await query(
    `SELECT u.id, u.username, u.first_name AS firstName FROM user_blocks b JOIN users u ON u.id = b.blocked_id
     WHERE b.blocker_id = ? ORDER BY b.created_at DESC`,
    [req.user.id]
  );
  return res.json({ blocks: rows });
});

router.post('/blocks/:userId', async (req, res) => {
  if (req.params.userId === req.user.id) return res.status(400).json({ error: 'Invalid input' });
  const [target] = await query(`SELECT id, role FROM users WHERE id = ?`, [req.params.userId]);
  if (!target) return res.status(404).json({ error: 'Not found' });
  if (isStaff(target)) return res.status(400).json({ error: 'Crew cannot be blocked' });
  await query(`INSERT IGNORE INTO user_blocks (blocker_id, blocked_id) VALUES (?, ?)`, [req.user.id, target.id]);
  return res.json({ ok: true });
});

router.delete('/blocks/:userId', async (req, res) => {
  await query(`DELETE FROM user_blocks WHERE blocker_id = ? AND blocked_id = ?`, [req.user.id, req.params.userId]);
  return res.json({ ok: true });
});

// --- Crew moderation ---

router.get('/reports', requireCrew, async (_req, res) => {
  const rows = await query(
    `SELECT r.id, r.reason, r.created_at AS createdAt, r.message_id AS messageId,
            cm.body, cm.deleted_at AS messageDeletedAt, cm.user_id AS authorId,
            au.username AS authorUsername, au.first_name AS authorFirstName, au.chat_banned AS authorBanned,
            ru.username AS reporterUsername,
            (SELECT COUNT(*) FROM community_reports r2 WHERE r2.message_id = r.message_id) AS reportCount
     FROM community_reports r
     JOIN community_messages cm ON cm.id = r.message_id
     JOIN users au ON au.id = cm.user_id
     JOIN users ru ON ru.id = r.reporter_id
     WHERE r.resolved_at IS NULL
     ORDER BY r.created_at DESC LIMIT 200`
  );
  const reports = rows.map((r) => ({
    ...r,
    messageId: String(r.messageId),
    messageDeleted: Boolean(r.messageDeletedAt),
    authorBanned: Boolean(r.authorBanned),
    reportCount: Number(r.reportCount),
  }));
  return res.json({ reports });
});

router.post('/reports/:id/resolve', requireCrew, async (req, res) => {
  const [report] = await query(`SELECT message_id FROM community_reports WHERE id = ?`, [req.params.id]);
  if (!report) return res.status(404).json({ error: 'Not found' });
  await query(
    `UPDATE community_reports SET resolved_at = UTC_TIMESTAMP(), resolved_by_user_id = ?
     WHERE message_id = ? AND resolved_at IS NULL`,
    [req.user.id, report.message_id]
  );
  return res.json({ ok: true });
});

router.post('/ban/:userId', requireCrew, async (req, res) => {
  const banned = Boolean(req.body?.banned);
  const result = await query(`UPDATE users SET chat_banned = ? WHERE id = ? AND role = 'student'`, [
    banned ? 1 : 0,
    req.params.userId,
  ]);
  if (!result.affectedRows) return res.status(404).json({ error: 'Not found' });
  await auditLog({ actorUserId: req.user.id, action: banned ? 'community.ban' : 'community.unban', targetType: 'user', targetId: req.params.userId, ip: req.ip });
  notifyUser(req.params.userId, { type: banned ? 'banned' : 'unbanned' });
  return res.json({ ok: true, banned });
});

export default router;
