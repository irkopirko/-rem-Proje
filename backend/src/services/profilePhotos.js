import { v4 as uuidv4 } from 'uuid';
import { query } from '../db.js';
import { deleteFromStorage, isStorageConfigured, storageCdnUrl, uploadToStorage } from './bunny.js';
import { detectImageMime } from './contentImages.js';

export const MAX_PROFILE_PHOTO_BYTES = 2 * 1024 * 1024;
const EXTENSIONS = { 'image/jpeg': 'jpg', 'image/png': 'png', 'image/webp': 'webp' };

export function profilePhotoUrl(id, storageKey) {
  return (storageKey && storageCdnUrl(storageKey)) || `/media/profile-photos/${id}`;
}

/**
 * Stores the new photo, points the user at it, then deletes every older photo (DB row + CDN file).
 * Each photo gets a fresh id, so the URL changes and no client keeps showing a cached old image.
 */
export async function replaceProfilePhoto(userId, buffer) {
  const mimeType = detectImageMime(buffer);
  if (!mimeType) return { status: 415, body: { error: 'Only JPEG, PNG or WebP images are allowed' } };
  if (buffer.length > MAX_PROFILE_PHOTO_BYTES) return { status: 413, body: { error: 'Payload too large' } };

  const id = uuidv4();
  let storageKey = null;
  if (isStorageConfigured()) {
    storageKey = `profile-photos/${userId}/${id}.${EXTENSIONS[mimeType]}`;
    await uploadToStorage(storageKey, buffer, mimeType);
  }
  await query(
    `INSERT INTO profile_photos (id, user_id, mime_type, byte_size, data, storage_key) VALUES (?, ?, ?, ?, ?, ?)`,
    [id, userId, mimeType, buffer.length, storageKey ? null : buffer, storageKey]
  );
  const url = profilePhotoUrl(id, storageKey);
  await query(`UPDATE users SET profile_photo_url = ? WHERE id = ?`, [url, userId]);
  await purgePhotos(userId, id);
  return { status: 200, url };
}

export async function removeProfilePhoto(userId) {
  await query(`UPDATE users SET profile_photo_url = NULL WHERE id = ?`, [userId]);
  await purgePhotos(userId, null);
}

/** Deletes all photos of the user except `keepId`, including their CDN copies. */
async function purgePhotos(userId, keepId) {
  const old = await query(
    `SELECT id, storage_key AS storageKey FROM profile_photos WHERE user_id = ? AND id <> ?`,
    [userId, keepId ?? '']
  );
  if (!old.length) return;
  await query(`DELETE FROM profile_photos WHERE user_id = ? AND id <> ?`, [userId, keepId ?? '']);
  await Promise.all(old.filter((p) => p.storageKey).map((p) => deleteFromStorage(p.storageKey).catch(() => {})));
}

/** CDN cleanup before a user row is hard-deleted (DB rows cascade). */
export async function deleteStoredPhotosForUser(userId) {
  const rows = await query(
    `SELECT storage_key AS storageKey FROM profile_photos WHERE user_id = ? AND storage_key IS NOT NULL`,
    [userId]
  );
  await Promise.all(rows.map((p) => deleteFromStorage(p.storageKey).catch(() => {})));
}

export async function readProfilePhoto(id) {
  const rows = await query(
    `SELECT mime_type AS mimeType, data, storage_key AS storageKey FROM profile_photos WHERE id = ? LIMIT 1`,
    [id]
  );
  return rows[0] ?? null;
}
