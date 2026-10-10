import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { v4 as uuidv4 } from 'uuid';
import { query } from '../db.js';
import { hashPassword } from '../utils/crypto.js';
import { replaceProfilePhoto } from './profilePhotos.js';

const CREW_AVATAR = path.join(path.dirname(fileURLToPath(import.meta.url)), '../../assets/crew-avatar.png');

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

  let rows = await query(`SELECT id, profile_photo_url AS photo FROM users WHERE email = ? LIMIT 1`, [email]);
  if (!rows.length) {
    const passwordHash = await hashPassword(password);
    const id = uuidv4();
    await query(
      `INSERT INTO users (id, username, email, password_hash, first_name, last_name, role, email_verified_at)
       VALUES (?, 'inkakademicrew', ?, ?, 'Ink Akademi', 'Crew', 'crew', UTC_TIMESTAMP())`,
      [id, email, passwordHash]
    );
    console.log('Crew portal account bootstrapped for', email);
    rows = [{ id, photo: null }];
  }

  await ensureCrewAvatar(rows[0].id);
}

async function ensureCrewAvatar(userId) {
  if (!fs.existsSync(CREW_AVATAR)) return;
  const result = await replaceProfilePhoto(userId, fs.readFileSync(CREW_AVATAR));
  if (result.status === 200) console.log('Crew portal avatar set');
}

export async function applyOfficialCrewAvatar() {
  const email = process.env.CREW_PORTAL_EMAIL?.toLowerCase();
  const rows = await query(
    `SELECT id FROM users WHERE username = 'inkakademicrew' OR email = ? LIMIT 1`,
    [email || '']
  );
  if (!rows.length) return { status: 404 };
  return ensureCrewAvatar(rows[0].id);
}
