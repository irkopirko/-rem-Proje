import { v4 as uuidv4 } from 'uuid';
import { query } from '../db.js';
import { deleteFromStorage, isStorageConfigured, storageCdnUrl, uploadToStorage } from './bunny.js';

export const MAX_IMAGE_BYTES = 5 * 1024 * 1024;
export const MAX_IMAGES_PER_OWNER = 30;

/**
 * Crew-authored images (shop products, homework instructions). Table/column names come from this
 * fixed map only, never from request input.
 */
export const IMAGE_KINDS = {
  product: { table: 'product_images', ownerColumn: 'product_id', ownerTable: 'products', path: 'product-images' },
  homework: { table: 'homework_images', ownerColumn: 'homework_id', ownerTable: 'homework', path: 'homework-images' },
};

const EXTENSIONS = { 'image/jpeg': 'jpg', 'image/png': 'png', 'image/webp': 'webp' };

/** Detects the real image type from magic bytes; the client-supplied Content-Type is not trusted. */
export function detectImageMime(buffer) {
  if (!Buffer.isBuffer(buffer) || buffer.length < 12) return null;
  if (buffer[0] === 0xff && buffer[1] === 0xd8 && buffer[2] === 0xff) return 'image/jpeg';
  if (buffer.subarray(0, 8).equals(Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]))) {
    return 'image/png';
  }
  if (buffer.subarray(0, 4).toString('ascii') === 'RIFF' && buffer.subarray(8, 12).toString('ascii') === 'WEBP') {
    return 'image/webp';
  }
  return null;
}

/** CDN URL when the image lives on Bunny Storage, otherwise our own `/media` fallback route. */
export function imageUrl(kind, imageId, storageKey) {
  if (storageKey) {
    const cdn = storageCdnUrl(storageKey);
    if (cdn) return cdn;
  }
  return `/media/${IMAGE_KINDS[kind].path}/${imageId}`;
}

/** Adds `images: [{ id, url }]` to each row, using `idKey` as the owner id. */
export async function attachImages(kind, rows, idKey = 'id') {
  const { table, ownerColumn } = IMAGE_KINDS[kind];
  const ids = [...new Set(rows.map((r) => r[idKey]))];
  if (!ids.length) return rows;
  const placeholders = ids.map(() => '?').join(',');
  const images = await query(
    `SELECT id, ${ownerColumn} AS ownerId, storage_key AS storageKey FROM ${table}
     WHERE ${ownerColumn} IN (${placeholders}) ORDER BY sort_order, created_at`,
    ids
  );
  const map = {};
  for (const image of images) {
    (map[image.ownerId] ??= []).push({ id: image.id, url: imageUrl(kind, image.id, image.storageKey) });
  }
  return rows.map((r) => ({ ...r, images: map[r[idKey]] ?? [] }));
}

/** Validates and stores an uploaded image; returns an HTTP-ish result object. */
export async function storeImage(kind, ownerId, buffer, uploadedBy) {
  const { table, ownerColumn, ownerTable, path } = IMAGE_KINDS[kind];
  const mimeType = detectImageMime(buffer);
  if (!mimeType) return { status: 415, body: { error: 'Only JPEG, PNG or WebP images are allowed' } };

  const owner = await query(`SELECT id FROM ${ownerTable} WHERE id = ? LIMIT 1`, [ownerId]);
  if (!owner.length) return { status: 404, body: { error: 'Not found' } };

  const [{ count, maxOrder }] = await query(
    `SELECT COUNT(*) AS count, COALESCE(MAX(sort_order), -1) AS maxOrder FROM ${table} WHERE ${ownerColumn} = ?`,
    [ownerId]
  );
  if (count >= MAX_IMAGES_PER_OWNER) {
    return { status: 409, body: { error: `At most ${MAX_IMAGES_PER_OWNER} images are allowed` } };
  }

  const id = uuidv4();
  let storageKey = null;
  if (isStorageConfigured()) {
    storageKey = `${path}/${ownerId}/${id}.${EXTENSIONS[mimeType]}`;
    await uploadToStorage(storageKey, buffer, mimeType);
  }
  await query(
    `INSERT INTO ${table} (id, ${ownerColumn}, mime_type, byte_size, data, storage_key, sort_order, uploaded_by_user_id)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
    [id, ownerId, mimeType, buffer.length, storageKey ? null : buffer, storageKey, Number(maxOrder) + 1, uploadedBy]
  );
  return { status: 201, body: { id, url: imageUrl(kind, id, storageKey) } };
}

export async function deleteImage(kind, imageId) {
  const { table } = IMAGE_KINDS[kind];
  const rows = await query(`SELECT storage_key AS storageKey FROM ${table} WHERE id = ?`, [imageId]);
  await query(`DELETE FROM ${table} WHERE id = ?`, [imageId]);
  if (rows[0]?.storageKey) await deleteFromStorage(rows[0].storageKey);
}

/** Removes CDN files before the owner row is deleted (DB rows go via ON DELETE CASCADE). */
export async function deleteImagesForOwners(kind, ownerIds) {
  if (!ownerIds.length) return;
  const { table, ownerColumn } = IMAGE_KINDS[kind];
  const placeholders = ownerIds.map(() => '?').join(',');
  const rows = await query(
    `SELECT storage_key AS storageKey FROM ${table} WHERE ${ownerColumn} IN (${placeholders}) AND storage_key IS NOT NULL`,
    ownerIds
  );
  await Promise.all(rows.map((r) => deleteFromStorage(r.storageKey)));
}

export async function readImage(kind, imageId) {
  const rows = await query(
    `SELECT mime_type AS mimeType, data, storage_key AS storageKey FROM ${IMAGE_KINDS[kind].table} WHERE id = ? LIMIT 1`,
    [imageId]
  );
  return rows[0] ?? null;
}
