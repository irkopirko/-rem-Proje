import { v4 as uuidv4 } from 'uuid';
import { query } from '../db.js';

export const ACADEMY_PROGRAM_ID = '6f0c1e2a-9b4d-4c3a-8f21-0a7e3b5d1c90';
export const ACADEMY_PROGRAM_SLUG = 'ink-akademi-egitimi';

export function programDTO(row) {
  return {
    id: row.id,
    slug: row.slug ?? null,
    title: row.title,
    description: row.description ?? null,
    instructorName: row.instructor_name ?? null,
    coverImageUrl: row.cover_image_url ?? null,
    sortOrder: Number(row.sort_order || 0),
    isPublished: row.is_published === undefined ? true : Boolean(row.is_published),
    moduleCount: Number(row.moduleCount ?? 0),
    videoCount: Number(row.videoCount ?? 0),
    completedCount: Number(row.completedCount ?? 0),
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

export async function createProgram({ title, description, instructorName, isPublished }) {
  const id = uuidv4();
  const sortOrder = await nextProgramSort();
  await query(
    `INSERT INTO education_programs (id, title, description, instructor_name, sort_order, is_published)
     VALUES (?, ?, ?, ?, ?, ?)`,
    [id, title, description ?? null, instructorName ?? null, sortOrder, isPublished === false ? 0 : 1]
  );
  const [row] = await query(`SELECT * FROM education_programs WHERE id = ?`, [id]);
  return programDTO(row);
}
