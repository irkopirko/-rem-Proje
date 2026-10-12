import { v4 as uuidv4 } from 'uuid';
import { query } from '../db.js';
import { deleteFromStorage, isStorageConfigured, storageCdnUrl, uploadToStorage } from './bunny.js';
import { detectImageMime } from './contentImages.js';

const COVER_EXTS = { 'image/jpeg': 'jpg', 'image/png': 'png', 'image/webp': 'webp' };
export const MAX_PROGRAM_COVER_BYTES = 5 * 1024 * 1024;

export const ACADEMY_PROGRAM_ID = '6f0c1e2a-9b4d-4c3a-8f21-0a7e3b5d1c90';
export const ACADEMY_PROGRAM_SLUG = 'ink-akademi-egitimi';

export function programDTO(row) {
  return {
    id: row.id,
    slug: row.slug ?? null,
    title: row.title,
    description: row.description ?? null,
    instructorName: row.instructor_name ?? null,
    coverImageUrl: row.cover_image_url ? programCoverPublicUrl(row.id, row.cover_image_url) : null,
    sortOrder: Number(row.sort_order || 0),
    isPublished: row.is_published === undefined ? true : Boolean(row.is_published),
    moduleCount: Number(row.moduleCount ?? 0),
    videoCount: Number(row.videoCount ?? 0),
    completedCount: Number(row.completedCount ?? 0),
    durationSeconds: Number(row.durationSeconds ?? row.duration_seconds ?? 0),
    accessLabel: row.accessLabel ?? row.access_label ?? null,
    displayIndex: Number(row.displayIndex ?? row.sort_order ?? 0),
  };
}

export function applyDisplayLabels(programs, modules) {
  const orderedPrograms = [...programs].sort((a, b) => Number(a.sort_order) - Number(b.sort_order) || String(a.id).localeCompare(String(b.id)));
  const indexById = new Map(orderedPrograms.map((program, index) => [program.id, index + 1]));
  const grouped = new Map();
  for (const module of modules) {
    const key = module.education_program_id || '_none';
    if (!grouped.has(key)) grouped.set(key, []);
    grouped.get(key).push(module);
  }
  for (const list of grouped.values()) {
    list.sort((a, b) => Number(a.sort_order) - Number(b.sort_order) || Number(a.module_number) - Number(b.module_number));
    list.forEach((module, index) => {
      const programIndex = indexById.get(module.education_program_id) || 0;
      module.displayLabel = programIndex ? `${programIndex}.${index + 1}` : String(index + 1);
      module.moduleIndex = index + 1;
    });
  }
  orderedPrograms.forEach((program, index) => {
    program.displayIndex = index + 1;
  });
  return { programs: orderedPrograms, modules };
}

export async function ensureAcademyProgram() {
  const [existing] = await query(`SELECT id FROM education_programs WHERE id = ? OR slug = ? LIMIT 1`, [
    ACADEMY_PROGRAM_ID,
    ACADEMY_PROGRAM_SLUG,
  ]);
  const id = existing?.id || ACADEMY_PROGRAM_ID;
  if (!existing) {
    await query(
      `INSERT INTO education_programs (id, slug, title, description, instructor_name, sort_order, is_published)
       VALUES (?, ?, ?, ?, ?, 1, 1)`,
      [
        id,
        ACADEMY_PROGRAM_SLUG,
        'INK AKADEMİ Eğitimi',
        'Ink Akademi’nin temel eğitim programı.',
        'Ink Akademi Crew',
      ]
    );
  }
  await query(`UPDATE modules SET education_program_id = ? WHERE education_program_id IS NULL`, [id]);
  return id;
}

export async function nextProgramSort() {
  const [row] = await query(`SELECT COALESCE(MAX(sort_order), 0) + 1 AS next FROM education_programs`);
  return Number(row?.next || 1);
}

export async function nextModuleSort(programId) {
  const [row] = await query(
    `SELECT COALESCE(MAX(sort_order), 0) + 1 AS next FROM modules WHERE education_program_id <=> ?`,
    [programId]
  );
  return Number(row?.next || 1);
}

export async function createProgram({ title, description, instructorName, isPublished, sortOrder }) {
  const id = uuidv4();
  const order = Number.isFinite(Number(sortOrder)) ? Number(sortOrder) : await nextProgramSort();
  await query(
    `INSERT INTO education_programs (id, title, description, instructor_name, sort_order, is_published)
     VALUES (?, ?, ?, ?, ?, ?)`,
    [id, title, description ?? null, instructorName ?? null, order, isPublished === false ? 0 : 1]
  );
  const [row] = await query(`SELECT * FROM education_programs WHERE id = ?`, [id]);
  return programDTO(row);
}

export function programCoverPublicUrl(programId, storedUrl) {
  if (storedUrl && /^https?:\/\//i.test(storedUrl)) return storedUrl;
  return storedUrl || `/media/program-covers/${programId}`;
}

export async function storeProgramCover(programId, buffer) {
  const mimeType = detectImageMime(buffer);
  if (!mimeType || !COVER_EXTS[mimeType]) {
    return { status: 415, body: { error: 'Sadece JPEG, PNG veya WebP yükleyebilirsin.' } };
  }
  if (buffer.length > MAX_PROGRAM_COVER_BYTES) {
    return { status: 413, body: { error: 'Kapak en fazla 5 MB olabilir.' } };
  }
  const [program] = await query(`SELECT id FROM education_programs WHERE id = ? LIMIT 1`, [programId]);
  if (!program) return { status: 404, body: { error: 'Not found' } };
  if (!isStorageConfigured()) return { status: 503, body: { error: 'Görsel depolama şu an kullanılamıyor' } };

  await deleteProgramCoverFiles(programId);
  const storageKey = `program-covers/${programId}/cover.${COVER_EXTS[mimeType]}`;
  await uploadToStorage(storageKey, buffer, mimeType);
  const url = storageCdnUrl(storageKey) || `/media/program-covers/${programId}`;
  await query(`UPDATE education_programs SET cover_image_url = ? WHERE id = ?`, [url, programId]);
  return { status: 200, body: { coverImageUrl: url } };
}

export async function readProgramCover(programId) {
  const [row] = await query(`SELECT cover_image_url AS url FROM education_programs WHERE id = ? LIMIT 1`, [programId]);
  if (!row?.url) return null;
  return { url: row.url };
}

export async function deleteProgramCoverFiles(programId) {
  await Promise.all(
    Object.values(COVER_EXTS).map((ext) => deleteFromStorage(`program-covers/${programId}/cover.${ext}`))
  );
}
