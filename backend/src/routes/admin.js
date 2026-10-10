import { Router } from 'express';
import { z } from 'zod';
import { v4 as uuidv4 } from 'uuid';
import { query } from '../db.js';
import { requireAuth, requireSuperAdmin } from '../middleware/auth.js';
import { hashPassword } from '../utils/crypto.js';
import { auditLog } from '../services/audit.js';
import { deleteStoredPhotosForUser } from '../services/profilePhotos.js';

const router = Router();
router.use(requireAuth, requireSuperAdmin);

router.get('/users', async (req, res) => {
  const includeDeleted = req.query.includeDeleted === '1';
  const rows = await query(
    `SELECT id, user_no AS userNo, username, email, first_name AS firstName, last_name AS lastName,
            role, membership_status AS membershipStatus, deleted_at AS deletedAt, created_at AS createdAt
     FROM users
     ${includeDeleted ? '' : 'WHERE deleted_at IS NULL'}
     ORDER BY user_no ASC`
  );
  return res.json({ users: rows });
});

router.post('/crew', async (req, res) => {
  const schema = z.object({
    email: z.string().email(),
    password: z.string().min(12),
    firstName: z.string().min(1),
    lastName: z.string().min(1),
  });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'Invalid input' });

  const email = parsed.data.email.toLowerCase();
  const exists = await query(`SELECT id FROM users WHERE email = ?`, [email]);
  if (exists.length) return res.status(409).json({ error: 'Email taken' });

  const id = uuidv4();
  const passwordHash = await hashPassword(parsed.data.password);
  await query(
    `INSERT INTO users (id, email, password_hash, first_name, last_name, role, email_verified_at)
     VALUES (?, ?, ?, ?, ?, 'crew', UTC_TIMESTAMP())`,
    [id, email, passwordHash, parsed.data.firstName, parsed.data.lastName]
  );
  await auditLog({
    actorUserId: req.user.id,
    action: 'crew.create',
    targetType: 'user',
    targetId: id,
    ip: req.ip,
  });
  return res.status(201).json({ id });
});

router.patch('/users/:id/role', async (req, res) => {
  const role = req.body?.role;
  if (!['student', 'crew', 'super_admin'].includes(role)) {
    return res.status(400).json({ error: 'Invalid role' });
  }
  if (req.params.id === req.user.id && role !== 'super_admin') {
    return res.status(400).json({ error: 'Cannot demote yourself' });
  }
  await query(`UPDATE users SET role = ? WHERE id = ?`, [role, req.params.id]);
  await auditLog({
    actorUserId: req.user.id,
    action: 'user.role_change',
    targetType: 'user',
    targetId: req.params.id,
    metadata: { role },
    ip: req.ip,
  });
  return res.json({ ok: true });
});

router.post('/users/:id/soft-delete', async (req, res) => {
  if (req.params.id === req.user.id) {
    return res.status(400).json({ error: 'Cannot delete yourself' });
  }
  await query(
    `UPDATE users SET deleted_at = UTC_TIMESTAMP(), deleted_by_user_id = ? WHERE id = ?`,
    [req.user.id, req.params.id]
  );
  await query(`UPDATE refresh_tokens SET revoked_at = UTC_TIMESTAMP() WHERE user_id = ?`, [
    req.params.id,
  ]);
  await auditLog({
    actorUserId: req.user.id,
    action: 'user.soft_delete',
    targetType: 'user',
    targetId: req.params.id,
    ip: req.ip,
  });
  return res.json({ ok: true });
});

/** Permanent purge — only super admin; removes user row (doc: only developer may truly delete) */
router.delete('/users/:id/purge', async (req, res) => {
  if (req.params.id === req.user.id) {
    return res.status(400).json({ error: 'Cannot purge yourself' });
  }
  const rows = await query(`SELECT role, email FROM users WHERE id = ?`, [req.params.id]);
  if (!rows.length) return res.status(404).json({ error: 'Not found' });

  await query(`DELETE FROM refresh_tokens WHERE user_id = ?`, [req.params.id]);
  await deleteStoredPhotosForUser(req.params.id);
  await query(`DELETE FROM users WHERE id = ?`, [req.params.id]);
  await auditLog({
    actorUserId: req.user.id,
    action: 'user.hard_purge',
    targetType: 'user',
    targetId: req.params.id,
    metadata: { email: rows[0].email, role: rows[0].role },
    ip: req.ip,
  });
  return res.json({ ok: true });
});

router.get('/audit', async (_req, res) => {
  const logs = await query(
    `SELECT id, actor_user_id AS actorUserId, action, target_type AS targetType,
            target_id AS targetId, metadata, created_at AS createdAt
     FROM audit_logs ORDER BY id DESC LIMIT 200`
  );
  return res.json({ logs });
});

export default router;
