import { v4 as uuidv4 } from 'uuid';
import { query } from '../db.js';
import { hashPassword } from '../utils/crypto.js';

export async function ensureSuperAdmin() {
  const email = process.env.SUPER_ADMIN_EMAIL;
  const password = process.env.SUPER_ADMIN_PASSWORD;
  if (!email || !password) return;

  const existing = await query(
    `SELECT id FROM users WHERE role = 'super_admin' AND deleted_at IS NULL LIMIT 1`
  );
  if (existing.length > 0) return;

  const id = uuidv4();
  const passwordHash = await hashPassword(password);
  await query(
    `INSERT INTO users (id, email, password_hash, first_name, last_name, role, email_verified_at)
     VALUES (?, ?, ?, 'Super', 'Admin', 'super_admin', UTC_TIMESTAMP())`,
    [id, email.toLowerCase(), passwordHash]
  );
  console.log('Super admin bootstrapped for', email);
}

/** Shared Ink Akademi Crew login (teacher panel), configured only through env vars. */
export async function ensureCrewPortal() {
  const email = process.env.CREW_PORTAL_EMAIL?.toLowerCase();
  const password = process.env.CREW_PORTAL_PASSWORD;
  if (!email || !password) return;

  const existing = await query(`SELECT id FROM users WHERE email = ? LIMIT 1`, [email]);
  if (existing.length > 0) return;

  const passwordHash = await hashPassword(password);
  await query(
    `INSERT INTO users (id, username, email, password_hash, first_name, last_name, role, email_verified_at)
     VALUES (?, 'inkakademicrew', ?, ?, 'Ink Akademi', 'Crew', 'crew', UTC_TIMESTAMP())`,
    [uuidv4(), email, passwordHash]
  );
  console.log('Crew portal account bootstrapped for', email);
}
