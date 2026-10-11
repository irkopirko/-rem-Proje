import express, { Router } from 'express';
import { z } from 'zod';
import { v4 as uuidv4 } from 'uuid';
import { query } from '../db.js';
import {
  hashPassword,
  verifyPassword,
  hashToken,
  randomOTP6,
  randomToken,
} from '../utils/crypto.js';
import { signAccessToken } from '../utils/jwt.js';
import {
  sendRegistrationOTP,
  sendWelcome,
  sendPasswordResetOTP,
  sendPasswordChanged,
} from '../services/mail.js';
import { requireAuth } from '../middleware/auth.js';
import { auditLog } from '../services/audit.js';
import { avatarFrame } from '../services/membership.js';
import { evaluateBadges } from '../services/badges.js';
import { levelFromXp } from '../services/levels.js';
import { broadcast } from '../services/community.js';
import { MAX_PROFILE_PHOTO_BYTES, removeProfilePhoto, replaceProfilePhoto } from '../services/profilePhotos.js';

const router = Router();

const passwordSchema = z
  .string()
  .min(8)
  .regex(/[a-z]/)
  .regex(/[A-Z]/)
  .regex(/[0-9]/)
  .regex(/[+\-*!]/);

const usernameSchema = z
  .string()
  .trim()
  .toLowerCase()
  .regex(/^[a-z0-9._]{3,20}$/)
  .refine((u) => !/^[._]|[._]$|\.\./.test(u));

const RESERVED_USERNAMES = new Set([
  'admin', 'administrator', 'root', 'support', 'destek', 'crew', 'inkakademi',
  'ink.akademi', 'inkakademicrew', 'moderator', 'system', 'superadmin',
]);

async function isUsernameTaken(username) {
  if (RESERVED_USERNAMES.has(username)) return true;
  const rows = await query(`SELECT id FROM users WHERE username = ? LIMIT 1`, [username]);
  return rows.length > 0;
}

function formatDate(value) {
  if (!value) return null;
  if (value instanceof Date) return value.toISOString().slice(0, 10);
  return String(value).slice(0, 10);
}

function publicUser(row) {
  return {
    id: row.id,
    username: row.username ?? null,
    birthDate: formatDate(row.birth_date),
    email: row.email,
    firstName: row.first_name,
    lastName: row.last_name,
    role: row.role,
    membershipStatus: row.membership_status,
    profilePhotoUrl: row.profile_photo_url,
    avatarFrame: avatarFrame(row),
    ...levelFromXp(row.xp),
    xp: Number(row.xp || 0),
  };
}

router.get('/username-available', async (req, res) => {
  const parsed = usernameSchema.safeParse(String(req.query.username ?? ''));
  if (!parsed.success) return res.json({ available: false, valid: false });
  return res.json({ available: !(await isUsernameTaken(parsed.data)), valid: true });
});

router.post('/register/start', async (req, res) => {
  const schema = z.object({
    firstName: z.string().trim().min(1).max(120),
    lastName: z.string().trim().min(1).max(120),
    username: usernameSchema,
    email: z.string().email(),
    password: passwordSchema,
    birthDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional(),
  });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: 'Invalid input', details: parsed.error.flatten() });
  }
  const { firstName, lastName, username, email, password, birthDate } = parsed.data;
  const normalized = email.toLowerCase();

  const existing = await query(`SELECT id FROM users WHERE email = ? LIMIT 1`, [normalized]);
  if (existing.length) {
    return res.status(409).json({ error: 'Email already registered' });
  }
  if (await isUsernameTaken(username)) {
    return res.status(409).json({ error: 'Username taken' });
  }

  const otp = randomOTP6();
  const otpHash = hashToken(otp);
  await query(`DELETE FROM otp_codes WHERE email = ? AND purpose = 'register'`, [normalized]);
  await query(
    `INSERT INTO otp_codes (id, email, code_hash, purpose, expires_at)
     VALUES (?, ?, ?, 'register', DATE_ADD(UTC_TIMESTAMP(), INTERVAL 15 MINUTE))`,
    [uuidv4(), normalized, otpHash]
  );

  // Staging payload in memory-safe way: store pending registration hash in otp metadata table extension
  // For simplicity store bcrypt hash temporarily in app_content keyed by email (cleared on verify)
  const pendingKey = `pending_reg:${normalized}`;
  const passwordHash = await hashPassword(password);
  await query(
    `INSERT INTO app_content (content_key, content_value) VALUES (?, ?)
     ON DUPLICATE KEY UPDATE content_value = VALUES(content_value)`,
    [
      pendingKey,
      JSON.stringify({ firstName, lastName, username, birthDate: birthDate ?? null, passwordHash }),
    ]
  );

  await sendRegistrationOTP(normalized, otp);
  return res.json({ ok: true, message: 'Verification code sent' });
});

router.post('/register/verify', async (req, res) => {
  const schema = z.object({ email: z.string().email(), code: z.string().length(6) });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'Invalid input' });

  const email = parsed.data.email.toLowerCase();
  const codeHash = hashToken(parsed.data.code);
  const otpRows = await query(
    `SELECT id FROM otp_codes
     WHERE email = ? AND purpose = 'register' AND code_hash = ? AND consumed_at IS NULL
       AND expires_at > UTC_TIMESTAMP() LIMIT 1`,
    [email, codeHash]
  );
  if (!otpRows.length) return res.status(400).json({ error: 'Invalid or expired code' });

  const pendingKey = `pending_reg:${email}`;
  const pendingRows = await query(`SELECT content_value FROM app_content WHERE content_key = ?`, [
    pendingKey,
  ]);
  if (!pendingRows.length) return res.status(400).json({ error: 'Registration expired' });
  const pending = JSON.parse(pendingRows[0].content_value);

  const userId = uuidv4();
  try {
    await query(
      `INSERT INTO users (id, username, email, password_hash, first_name, last_name, birth_date, role, membership_status, email_verified_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, 'student', 'trial', UTC_TIMESTAMP())`,
      [
        userId,
        pending.username,
        email,
        pending.passwordHash,
        pending.firstName,
        pending.lastName,
        pending.birthDate,
      ]
    );
  } catch (err) {
    if (err?.code === 'ER_DUP_ENTRY') {
      const field = String(err.sqlMessage || '').includes('username') ? 'Username taken' : 'Email already registered';
      return res.status(409).json({ error: field });
    }
    throw err;
  }
  await query(`UPDATE otp_codes SET consumed_at = UTC_TIMESTAMP() WHERE id = ?`, [otpRows[0].id]);
  await query(`DELETE FROM app_content WHERE content_key = ?`, [pendingKey]);
  await query(
    `INSERT IGNORE INTO homework_assignments (id, homework_id, student_id)
     SELECT UUID(), h.id, ? FROM homework h WHERE h.assign_to_all = 1 AND h.is_published = 1`,
    [userId]
  );
  await sendWelcome(email);
  await evaluateBadges(userId);

  const userRows = await query(`SELECT * FROM users WHERE id = ?`, [userId]);
  const user = userRows[0];
  const accessToken = signAccessToken(user);
  const refresh = randomToken();
  await query(
    `INSERT INTO refresh_tokens (id, user_id, token_hash, expires_at)
     VALUES (?, ?, ?, DATE_ADD(UTC_TIMESTAMP(), INTERVAL 30 DAY))`,
    [uuidv4(), userId, hashToken(refresh)]
  );

  return res.json({ accessToken, refreshToken: refresh, user: publicUser(user) });
});

router.post('/login', async (req, res) => {
  // `identifier` is either an e-mail or a username; `email` kept for older clients.
  const schema = z.object({
    identifier: z.string().trim().min(1).max(255).optional(),
    email: z.string().trim().min(1).max(255).optional(),
    password: z.string().min(1),
  });
  const parsed = schema.safeParse(req.body);
  const identifier = (parsed.success && (parsed.data.identifier ?? parsed.data.email))?.toLowerCase();
  if (!parsed.success || !identifier) return res.status(400).json({ error: 'Invalid input' });

  const column = identifier.includes('@') ? 'email' : 'username';
  const rows = await query(`SELECT * FROM users WHERE ${column} = ? AND deleted_at IS NULL LIMIT 1`, [
    identifier,
  ]);
  const user = rows[0];
  if (!user || !(await verifyPassword(parsed.data.password, user.password_hash))) {
    return res.status(401).json({ error: 'Invalid email or password' });
  }
  if (!user.email_verified_at && user.role === 'student') {
    return res.status(403).json({ error: 'Email not verified' });
  }

  if (user.role === 'student') await evaluateBadges(user.id);
  const [fresh] = await query(`SELECT * FROM users WHERE id = ?`, [user.id]);
  const account = fresh ?? user;

  const accessToken = signAccessToken(user);
  const refresh = randomToken();
  await query(
    `INSERT INTO refresh_tokens (id, user_id, token_hash, expires_at)
     VALUES (?, ?, ?, DATE_ADD(UTC_TIMESTAMP(), INTERVAL 30 DAY))`,
    [uuidv4(), user.id, hashToken(refresh)]
  );
  return res.json({ accessToken, refreshToken: refresh, user: publicUser(account) });
});

// Refresh tokens are opaque random strings (only their hash is stored) and rotate on every use.
router.post('/refresh', async (req, res) => {
  const token = req.body?.refreshToken;
  if (typeof token !== 'string' || token.length < 20 || token.length > 512) {
    return res.status(400).json({ error: 'Missing refresh token' });
  }
  const rows = await query(
    `SELECT rt.id AS token_id, u.* FROM refresh_tokens rt
     JOIN users u ON u.id = rt.user_id
     WHERE rt.token_hash = ? AND rt.revoked_at IS NULL AND rt.expires_at > UTC_TIMESTAMP()
       AND u.deleted_at IS NULL LIMIT 1`,
    [hashToken(token)]
  );
  if (!rows.length) return res.status(401).json({ error: 'Invalid refresh token' });
  const user = rows[0];

  const revoked = await query(
    `UPDATE refresh_tokens SET revoked_at = UTC_TIMESTAMP() WHERE id = ? AND revoked_at IS NULL`,
    [user.token_id]
  );
  if (!revoked.affectedRows) return res.status(401).json({ error: 'Invalid refresh token' });

  const next = randomToken();
  await query(
    `INSERT INTO refresh_tokens (id, user_id, token_hash, expires_at)
     VALUES (?, ?, ?, DATE_ADD(UTC_TIMESTAMP(), INTERVAL 30 DAY))`,
    [uuidv4(), user.id, hashToken(next)]
  );
  return res.json({ accessToken: signAccessToken(user), refreshToken: next });
});

router.post('/password/forgot', async (req, res) => {
  const email = String(req.body?.email || '').toLowerCase();
  if (!email) return res.status(400).json({ error: 'Email required' });
  const otp = randomOTP6();
  await query(`DELETE FROM otp_codes WHERE email = ? AND purpose = 'password_reset'`, [email]);
  await query(
    `INSERT INTO otp_codes (id, email, code_hash, purpose, expires_at)
     VALUES (?, ?, ?, 'password_reset', DATE_ADD(UTC_TIMESTAMP(), INTERVAL 15 MINUTE))`,
    [uuidv4(), email, hashToken(otp)]
  );
  await sendPasswordResetOTP(email, otp);
  return res.json({ ok: true });
});

router.post('/password/reset', async (req, res) => {
  const schema = z.object({
    email: z.string().email(),
    code: z.string().length(6),
    newPassword: passwordSchema,
  });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'Invalid input' });
  const email = parsed.data.email.toLowerCase();
  const codeHash = hashToken(parsed.data.code);
  const otpRows = await query(
    `SELECT id FROM otp_codes WHERE email = ? AND purpose = 'password_reset'
     AND code_hash = ? AND consumed_at IS NULL AND expires_at > UTC_TIMESTAMP() LIMIT 1`,
    [email, codeHash]
  );
  if (!otpRows.length) return res.status(400).json({ error: 'Invalid or expired code' });

  const passwordHash = await hashPassword(parsed.data.newPassword);
  await query(`UPDATE users SET password_hash = ? WHERE email = ?`, [passwordHash, email]);
  await query(`UPDATE otp_codes SET consumed_at = UTC_TIMESTAMP() WHERE id = ?`, [otpRows[0].id]);
  await sendPasswordChanged(email);
  return res.json({ ok: true });
});

router.post('/password/change', requireAuth, async (req, res) => {
  const schema = z.object({
    currentPassword: z.string().min(1),
    newPassword: passwordSchema,
  });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'Invalid input' });

  const rows = await query(`SELECT password_hash FROM users WHERE id = ?`, [req.user.id]);
  if (!(await verifyPassword(parsed.data.currentPassword, rows[0].password_hash))) {
    return res.status(401).json({ error: 'Current password incorrect' });
  }
  const passwordHash = await hashPassword(parsed.data.newPassword);
  await query(`UPDATE users SET password_hash = ? WHERE id = ?`, [passwordHash, req.user.id]);
  await sendPasswordChanged(req.user.email);
  return res.json({ ok: true });
});

router.get('/me', requireAuth, async (req, res) => {
  if (req.user.role === 'student') await evaluateBadges(req.user.id);
  const rows = await query(`SELECT * FROM users WHERE id = ?`, [req.user.id]);
  return res.json({ user: publicUser(rows[0]) });
});

// Identity fields (name, username, e-mail, birth date) are read-only for students;
// only crew/super admin can correct them via the admin routes. The photo is the only
// self-editable field and is always uploaded to us, never an arbitrary external URL.
const rawPhoto = express.raw({ type: () => true, limit: MAX_PROFILE_PHOTO_BYTES });

router.put('/me/photo', requireAuth, rawPhoto, async (req, res) => {
  if (!Buffer.isBuffer(req.body) || !req.body.length) return res.status(400).json({ error: 'Invalid input' });
  const result = await replaceProfilePhoto(req.user.id, req.body);
  if (result.status !== 200) return res.status(result.status).json(result.body);
  broadcast({ type: 'profile', userId: req.user.id, photoUrl: result.url });
  await evaluateBadges(req.user.id);
  const rows = await query(`SELECT * FROM users WHERE id = ?`, [req.user.id]);
  return res.json({ user: publicUser(rows[0]) });
});

router.delete('/me/photo', requireAuth, async (req, res) => {
  await removeProfilePhoto(req.user.id);
  broadcast({ type: 'profile', userId: req.user.id, photoUrl: null });
  const rows = await query(`SELECT * FROM users WHERE id = ?`, [req.user.id]);
  return res.json({ user: publicUser(rows[0]) });
});

router.delete('/me', requireAuth, async (req, res) => {
  const schema = z.object({ password: z.string().min(1) });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'Invalid input' });

  const rows = await query(`SELECT * FROM users WHERE id = ? AND deleted_at IS NULL`, [req.user.id]);
  const user = rows[0];
  if (!user) return res.status(404).json({ error: 'Not found' });
  if (user.role === 'super_admin') {
    return res.status(403).json({ error: 'Super admin account cannot be self-deleted' });
  }
  if (!(await verifyPassword(parsed.data.password, user.password_hash))) {
    return res.status(401).json({ error: 'Current password incorrect' });
  }

  // Free e-mail and username so they can be reused; full purge stays with the super admin.
  const tombstone = `deleted+${user.id}@deleted.invalid`;
  await query(
    `UPDATE users SET deleted_at = UTC_TIMESTAMP(), deleted_by_user_id = ?, purge_requested_at = UTC_TIMESTAMP(),
       email = ?, username = NULL
     WHERE id = ?`,
    [user.id, tombstone, user.id]
  );
  await query(`UPDATE refresh_tokens SET revoked_at = UTC_TIMESTAMP() WHERE user_id = ? AND revoked_at IS NULL`, [
    user.id,
  ]);
  await removeProfilePhoto(user.id);
  await auditLog({
    actorUserId: user.id,
    action: 'user.self_delete',
    targetType: 'user',
    targetId: user.id,
    metadata: { email: user.email, username: user.username },
    ip: req.ip,
  });
  return res.json({ ok: true });
});

router.post('/logout', requireAuth, async (req, res) => {
  const refresh = req.body?.refreshToken;
  if (refresh) {
    await query(`UPDATE refresh_tokens SET revoked_at = UTC_TIMESTAMP() WHERE token_hash = ?`, [
      hashToken(refresh),
    ]);
  }
  return res.json({ ok: true });
});

export default router;
