import { v4 as uuidv4 } from 'uuid';
import { query } from '../db.js';
import { isStorageConfigured, storageCdnUrl, storagePutTarget, uploadToStorage } from './bunny.js';

export const MAX_HOMEWORK_TOTAL_BYTES = 2 * 1024 * 1024 * 1024;
export const MAX_HOMEWORK_PROXY_BYTES = 8 * 1024 * 1024;
/** @deprecated alias for the small proxy path */
export const MAX_HOMEWORK_FILE_BYTES = MAX_HOMEWORK_PROXY_BYTES;

const EXTENSIONS = { 'image/jpeg': 'jpg', 'image/png': 'png', 'application/pdf': 'pdf' };
const MIME_BY_EXT = { jpg: 'image/jpeg', jpeg: 'image/jpeg', png: 'image/png', pdf: 'application/pdf' };
const KEY_RE = /^homework-submissions\/([0-9a-f-]{36})\/([0-9a-f-]{36})\.(jpg|png|pdf)$/i;

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

export function normalizeHomeworkMime(value) {
  const mime = String(value || '').trim().toLowerCase();
  if (mime === 'image/jpg') return 'image/jpeg';
  return EXTENSIONS[mime] ? mime : null;
}

function fileDTO(row) {
  return {
    id: row.id,
    url: homeworkSubmissionUrl(row.id, row.storageKey),
    mime: row.mimeType,
    size: Number(row.fileSize || 0),
    name: row.fileName || null,
  };
}

export async function assignmentFileBytes(assignmentId) {
  const rows = await query(
    `SELECT COALESCE(SUM(COALESCE(file_size, LENGTH(data), 0)), 0) AS total
     FROM homework_submissions WHERE assignment_id = ?`,
    [assignmentId]
  );
  return Number(rows[0]?.total || 0);
}

export async function listHomeworkFiles(assignmentId) {
  const rows = await query(
    `SELECT id, file_mime AS mimeType, file_size AS fileSize, file_name AS fileName, storage_key AS storageKey
     FROM homework_submissions WHERE assignment_id = ? ORDER BY submitted_at ASC, id ASC`,
    [assignmentId]
  );
  return rows.map(fileDTO);
}

export async function listHomeworkFilesByAssignments(assignmentIds) {
  const ids = [...new Set((assignmentIds || []).map((id) => String(id || '').trim()).filter(Boolean))];
  if (!ids.length) return new Map();
  const placeholders = ids.map(() => '?').join(', ');
  const rows = await query(
    `SELECT id, assignment_id AS assignmentId, file_mime AS mimeType, file_size AS fileSize,
            file_name AS fileName, storage_key AS storageKey
     FROM homework_submissions
     WHERE assignment_id IN (${placeholders})
     ORDER BY submitted_at ASC, id ASC`,
    ids
  );
  const map = new Map();
  for (const row of rows) {
    const list = map.get(row.assignmentId) || [];
    list.push(fileDTO(row));
    map.set(row.assignmentId, list);
  }
  return map;
}

export async function beginHomeworkFileUpload(assignmentId, { mimeType, size, name } = {}) {
  const mime = normalizeHomeworkMime(mimeType);
  if (!mime) return { status: 415, body: { error: 'Only JPEG, PNG or PDF files are allowed' } };
  const bytes = Number(size);
  if (!Number.isFinite(bytes) || bytes <= 0) return { status: 400, body: { error: 'Invalid file' } };
  if (!isStorageConfigured()) {
    return { status: 503, body: { error: 'Büyük dosya yüklemesi için depolama yapılandırılmalı.' } };
  }
  const used = await assignmentFileBytes(assignmentId);
  const remaining = MAX_HOMEWORK_TOTAL_BYTES - used;
  if (bytes > remaining) {
    return { status: 413, body: { error: 'Dosyaların toplamı en fazla 2 GB olabilir.' } };
  }
  const id = uuidv4();
  const key = `homework-submissions/${assignmentId}/${id}.${EXTENSIONS[mime]}`;
  const target = storagePutTarget(key, mime);
  if (!target) return { status: 503, body: { error: 'Büyük dosya yüklemesi için depolama yapılandırılmalı.' } };
  return {
    status: 200,
    upload: {
      ...target,
      id,
      maxBytes: remaining,
      remainingBytes: remaining,
      mimeType: mime,
      fileName: sanitizeFileName(name, mime),
    },
  };
}

export async function confirmHomeworkFile(assignmentId, { key, mimeType, size, name } = {}) {
  const parsed = parseHomeworkKey(key);
  if (!parsed || parsed.assignmentId !== assignmentId) {
    return { status: 400, body: { error: 'Invalid file' } };
  }
  const mime = normalizeHomeworkMime(mimeType) || MIME_BY_EXT[parsed.ext];
  if (!mime || EXTENSIONS[mime] !== parsed.ext) {
    return { status: 415, body: { error: 'Only JPEG, PNG or PDF files are allowed' } };
  }
  const bytes = Number(size);
  if (!Number.isFinite(bytes) || bytes <= 0) return { status: 400, body: { error: 'Invalid file' } };
  const used = await assignmentFileBytes(assignmentId);
  if (used + bytes > MAX_HOMEWORK_TOTAL_BYTES) {
    return { status: 413, body: { error: 'Dosyaların toplamı en fazla 2 GB olabilir.' } };
  }
  const url = homeworkSubmissionUrl(parsed.id, parsed.key);
  try {
    await query(
      `INSERT INTO homework_submissions (id, assignment_id, file_url, file_mime, data, storage_key, file_size, file_name)
       VALUES (?, ?, ?, ?, NULL, ?, ?, ?)`,
      [parsed.id, assignmentId, url, mime, parsed.key, bytes, sanitizeFileName(name, mime)]
    );
  } catch (err) {
    if (err?.code === 'ER_DUP_ENTRY') {
      return { status: 200, url, mimeType: mime, id: parsed.id };
    }
    throw err;
  }
  return { status: 200, url, mimeType: mime, id: parsed.id };
}

export async function storeHomeworkSubmission(assignmentId, buffer, { name } = {}) {
  const mimeType = detectHomeworkMime(buffer);
  if (!mimeType) return { status: 415, body: { error: 'Only JPEG, PNG or PDF files are allowed' } };
  const used = await assignmentFileBytes(assignmentId);
  if (used + buffer.length > MAX_HOMEWORK_TOTAL_BYTES) {
    return { status: 413, body: { error: 'Dosyaların toplamı en fazla 2 GB olabilir.' } };
  }
  if (buffer.length > MAX_HOMEWORK_PROXY_BYTES && !isStorageConfigured()) {
    return { status: 413, body: { error: 'Payload too large' } };
  }

  const id = uuidv4();
  let storageKey = null;
  if (isStorageConfigured()) {
    storageKey = `homework-submissions/${assignmentId}/${id}.${EXTENSIONS[mimeType]}`;
    await uploadToStorage(storageKey, buffer, mimeType);
  }
  const url = homeworkSubmissionUrl(id, storageKey);
  await query(
    `INSERT INTO homework_submissions (id, assignment_id, file_url, file_mime, data, storage_key, file_size, file_name)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
    [
      id,
      assignmentId,
      url,
      mimeType,
      storageKey ? null : buffer,
      storageKey,
      buffer.length,
      sanitizeFileName(name, mimeType),
    ]
  );
  return { status: 200, url, mimeType, id };
}

export async function readHomeworkSubmission(id) {
  const rows = await query(
    `SELECT file_mime AS mimeType, data, storage_key AS storageKey
     FROM homework_submissions WHERE id = ? LIMIT 1`,
    [id]
  );
  return rows[0] ?? null;
}

function parseHomeworkKey(key) {
  const match = String(key || '').trim().match(KEY_RE);
  if (!match) return null;
  return { assignmentId: match[1], id: match[2], ext: match[3].toLowerCase(), key: match[0] };
}

function sanitizeFileName(name, mimeType) {
  const raw = String(name || '').trim().replace(/[/\\]/g, '').slice(0, 180);
  if (raw) return raw;
  return `odev.${EXTENSIONS[mimeType] || 'bin'}`;
}
