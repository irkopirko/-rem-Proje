import { v4 as uuidv4 } from 'uuid';
import { query } from '../db.js';
import { deleteFromStorage, isStorageConfigured, storageCdnUrl, storagePutTarget } from './bunny.js';

const KEY_ROW = 'guide_pdf_key';
const LEGACY_URL_ROW = 'guide_pdf_url';
export const MAX_GUIDE_BYTES = 400 * 1024 * 1024;

const KEY_RE = /^guide\/ink-akademi-rehberi-[0-9a-f-]{36}\.pdf$/i;

export function isGuideKey(key) {
  return KEY_RE.test(String(key || ''));
}

async function storedKey() {
  const rows = await query(`SELECT content_value FROM app_content WHERE content_key = ?`, [KEY_ROW]);
  return rows[0]?.content_value || null;
}

export async function guideForStudent() {
  const key = await storedKey();
  if (key && isStorageConfigured()) {
    return { available: true, pdfUrl: storageCdnUrl(key) };
  }
  const legacy = await query(`SELECT content_value FROM app_content WHERE content_key = ?`, [LEGACY_URL_ROW]);
  const pdfUrl = legacy[0]?.content_value || null;
  return { available: Boolean(pdfUrl), pdfUrl };
}

export async function guideForCrew() {
  const status = await guideForStudent();
  return { ...status, storageConfigured: isStorageConfigured(), maxBytes: MAX_GUIDE_BYTES };
}

export function beginGuideUpload() {
  if (!isStorageConfigured()) return null;
  const key = `guide/ink-akademi-rehberi-${uuidv4()}.pdf`;
  const target = storagePutTarget(key, 'application/pdf');
  if (!target) return null;
  return { ...target, maxBytes: MAX_GUIDE_BYTES };
}

export async function confirmGuideUpload(key) {
  if (!isGuideKey(key)) {
    const err = new Error('Invalid guide key');
    err.status = 400;
    throw err;
  }
  const previous = await storedKey();
  await query(
    `INSERT INTO app_content (content_key, content_value) VALUES (?, ?)
     ON DUPLICATE KEY UPDATE content_value = VALUES(content_value)`,
    [KEY_ROW, key]
  );
  if (previous && previous !== key) await deleteFromStorage(previous);
  return guideForCrew();
}
