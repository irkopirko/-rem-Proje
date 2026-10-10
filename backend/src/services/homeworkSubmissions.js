import { v4 as uuidv4 } from 'uuid';
import { query } from '../db.js';
import { deleteFromStorage, isStorageConfigured, storageCdnUrl, uploadToStorage } from './bunny.js';

export const MAX_HOMEWORK_FILE_BYTES = 10 * 1024 * 1024;
const EXTENSIONS = { 'image/jpeg': 'jpg', 'image/png': 'png', 'application/pdf': 'pdf' };

export function homeworkSubmissionUrl(id, storageKey) {
  return (storageKey && storageCdnUrl(storageKey)) || `/media/homework-submissions/${id}`;
}

/** Trusts file bytes, not the client Content-Type. JPEG, PNG or PDF only. */
export function detectHomeworkMime(buffer) {
  if (!Buffer.isBuffer(buffer) || buffer.length < 5) return null;
  if (buffer[0] === 0xff && buffer[1] === 0xd8 && buffer[2] === 0xff) return 'image/jpeg';
  if (buffer.subarray(0, 8).equals(Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]))) {
    return 'image/png';
  }
  if (buffer.subarray(0, 4).toString('ascii') === '%PDF') return 'application/pdf';
  return null;
}

export async function storeHomeworkSubmission(assignmentId, buffer) {
  const mimeType = detectHomeworkMime(buffer);
  if (!mimeType) return { status: 415, body: { error: 'Only JPEG, PNG or PDF files are allowed' } };
  if (buffer.length > MAX_HOMEWORK_FILE_BYTES) return { status: 413, body: { error: 'Payload too large' } };

  const id = uuidv4();
  let storageKey = null;
  if (isStorageConfigured()) {
    storageKey = `homework-submissions/${assignmentId}/${id}.${EXTENSIONS[mimeType]}`;
    await uploadToStorage(storageKey, buffer, mimeType);
  }
  const url = homeworkSubmissionUrl(id, storageKey);
  await query(
    `INSERT INTO homework_submissions (id, assignment_id, file_url, file_mime, data, storage_key)
     VALUES (?, ?, ?, ?, ?, ?)`,
    [id, assignmentId, url, mimeType, storageKey ? null : buffer, storageKey]
  );
  return { status: 200, url, mimeType };
}

export async function readHomeworkSubmission(id) {
  const rows = await query(
    `SELECT file_mime AS mimeType, data, storage_key AS storageKey
     FROM homework_submissions WHERE id = ? LIMIT 1`,
    [id]
  );
  return rows[0] ?? null;
}
