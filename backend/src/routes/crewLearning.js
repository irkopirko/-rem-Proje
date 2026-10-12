import express, { Router } from 'express';
import { z } from 'zod';
import { v4 as uuidv4 } from 'uuid';
import { query } from '../db.js';
import { requireAuth, requireCrew } from '../middleware/auth.js';
import { auditLog } from '../services/audit.js';
import {
  createStreamVideo,
  deleteStreamVideo,
  isStreamConfigured,
  tusCredentials,
} from '../services/bunny.js';
import { refreshStaleProcessing, syncVideoFromBunny, videoDTO } from '../services/videoCatalog.js';
import {
  applyDisplayLabels,
  createProgram,
  deleteProgramCoverFiles,
  ensureAcademyProgram,
  MAX_PROGRAM_COVER_BYTES,
  nextModuleSort,
  programDTO,
  storeProgramCover,
} from '../services/programs.js';

const router = Router();
router.use(requireAuth, requireCrew);

const programSchema = z.object({
  title: z.string().trim().min(1).max(255),
  description: z.string().trim().max(10000).optional(),
  instructorName: z.string().trim().max(160).optional(),
  isPublished: z.boolean().optional(),
  sortOrder: z.number().int().min(0).max(999).optional(),
});

const rawCover = express.raw({ type: () => true, limit: MAX_PROGRAM_COVER_BYTES });

const moduleSchema = z.object({
  title: z.string().trim().min(1).max(255),
  description: z.string().trim().max(10000).optional(),
  isPublished: z.boolean().optional(),
  educationProgramId: z.string().uuid().optional().nullable(),
});

const videoSchema = z.object({
  title: z.string().trim().min(1).max(255),
  description: z.string().trim().max(10000).optional(),
  isPublished: z.boolean().optional(),
  allowTrial: z.boolean().optional(),
});

function moduleDTO(row) {
  return {
    id: row.id,
    educationProgramId: row.education_program_id ?? null,
    moduleNumber: Number(row.module_number),
    title: row.title,
    description: row.description,
    sortOrder: row.sort_order,
    isPublished: Boolean(row.is_published),
    videoCount: Number(row.video_count ?? 0),
    readyCount: Number(row.ready_count ?? 0),
    displayLabel: row.displayLabel || null,
  };
}

router.get('/programs', async (_req, res) => {
  const programs = await query(
    `SELECT p.*,
            (SELECT COUNT(*) FROM modules m WHERE m.education_program_id = p.id) AS moduleCount,
            (SELECT COUNT(*) FROM videos v JOIN modules m ON m.id = v.module_id
              WHERE m.education_program_id = p.id) AS videoCount,
            (SELECT COUNT(*) FROM videos v JOIN modules m ON m.id = v.module_id
              WHERE m.education_program_id = p.id AND v.status = 'ready') AS completedCount
     FROM education_programs p
     ORDER BY p.sort_order, p.title`
  );
  const labeled = applyDisplayLabels(programs, []);
  return res.json({ programs: labeled.programs.map((row) => programDTO(row)) });
});

router.post('/programs', async (req, res) => {
  const parsed = programSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'Invalid input' });
  const created = await createProgram(parsed.data);
  await auditLog({
    actorUserId: req.user.id,
    action: 'program.create',
    targetType: 'education_program',
    targetId: created.id,
    ip: req.ip,
  });
  return res.status(201).json({ program: created });
});

router.post('/programs/:id/cover', rawCover, async (req, res) => {
  if (!Buffer.isBuffer(req.body) || !req.body.length) return res.status(400).json({ error: 'Invalid file' });
  const result = await storeProgramCover(req.params.id, req.body);
  if (result.status === 200) {
    await auditLog({
      actorUserId: req.user.id,
      action: 'program.cover',
      targetType: 'education_program',
      targetId: req.params.id,
      ip: req.ip,
    });
  }
  return res.status(result.status).json(result.body);
});

router.patch('/programs/:id', async (req, res) => {
  const parsed = programSchema.partial().safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'Invalid input' });
  const { title, description, instructorName, isPublished, sortOrder } = parsed.data;
  const result = await query(
    `UPDATE education_programs SET
       title = COALESCE(?, title),
       description = COALESCE(?, description),
       instructor_name = COALESCE(?, instructor_name),
       is_published = COALESCE(?, is_published),
       sort_order = COALESCE(?, sort_order)
     WHERE id = ?`,
    [
      title ?? null,
      description ?? null,
      instructorName ?? null,
      isPublished === undefined ? null : isPublished ? 1 : 0,
      sortOrder === undefined ? null : sortOrder,
      req.params.id,
    ]
  );
  if (!result.affectedRows) return res.status(404).json({ error: 'Not found' });
  await auditLog({
    actorUserId: req.user.id,
    action: 'program.update',
    targetType: 'education_program',
    targetId: req.params.id,
    ip: req.ip,
  });
  return res.json({ ok: true });
});

router.delete('/programs/:id', async (req, res) => {
  const [{ count }] = await query(
    `SELECT COUNT(*) AS count FROM modules WHERE education_program_id = ?`,
    [req.params.id]
  );
  if (Number(count) > 0) {
    return res.status(409).json({ error: 'Bu eğitimde modül var. Önce modülleri taşı veya sil.' });
  }
  const result = await query(`DELETE FROM education_programs WHERE id = ?`, [req.params.id]);
  if (!result.affectedRows) return res.status(404).json({ error: 'Not found' });
  await deleteProgramCoverFiles(req.params.id);
  await auditLog({
    actorUserId: req.user.id,
    action: 'program.delete',
    targetType: 'education_program',
    targetId: req.params.id,
    ip: req.ip,
  });
  return res.json({ ok: true });
});

router.get('/modules', async (_req, res) => {
  const programs = await query(
    `SELECT p.*,
            (SELECT COUNT(*) FROM modules m WHERE m.education_program_id = p.id) AS moduleCount,
            (SELECT COUNT(*) FROM videos v JOIN modules m ON m.id = v.module_id
              WHERE m.education_program_id = p.id) AS videoCount,
            (SELECT COUNT(*) FROM videos v JOIN modules m ON m.id = v.module_id
              WHERE m.education_program_id = p.id AND v.status = 'ready') AS completedCount
     FROM education_programs p
     ORDER BY p.sort_order, p.title`
  );
  const rows = await query(
    `SELECT m.*,
            (SELECT COUNT(*) FROM videos v WHERE v.module_id = m.id) AS video_count,
            (SELECT COUNT(*) FROM videos v WHERE v.module_id = m.id AND v.status = 'ready') AS ready_count
     FROM modules m
     LEFT JOIN education_programs p ON p.id = m.education_program_id
     ORDER BY COALESCE(p.sort_order, 999), m.sort_order, m.module_number`
  );
  const labeled = applyDisplayLabels(programs, rows);
  return res.json({
    programs: labeled.programs.map((row) => programDTO(row)),
    modules: labeled.modules.map(moduleDTO),
    videoServiceConfigured: isStreamConfigured(),
  });
});

router.post('/modules', async (req, res) => {
  const parsed = moduleSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'Invalid input' });
  const [{ next }] = await query(`SELECT COALESCE(MAX(module_number), 0) + 1 AS next FROM modules`);
  const programId = parsed.data.educationProgramId ?? (await ensureAcademyProgram());
  if (programId) {
    const [program] = await query(`SELECT id FROM education_programs WHERE id = ? LIMIT 1`, [programId]);
    if (!program) return res.status(400).json({ error: 'Eğitim bulunamadı' });
  }
  const sortOrder = await nextModuleSort(programId);
  const id = uuidv4();
  await query(
    `INSERT INTO modules (id, education_program_id, module_number, title, description, sort_order, is_published)
     VALUES (?, ?, ?, ?, ?, ?, ?)`,
    [id, programId, next, parsed.data.title, parsed.data.description ?? null, sortOrder, parsed.data.isPublished === false ? 0 : 1]
  );
  await auditLog({ actorUserId: req.user.id, action: 'module.create', targetType: 'module', targetId: id, ip: req.ip });
  const [row] = await query(`SELECT * FROM modules WHERE id = ?`, [id]);
  return res.status(201).json({ id, module: moduleDTO(row) });
});

router.patch('/modules/:id', async (req, res) => {
  const parsed = moduleSchema.partial().safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'Invalid input' });
  const { title, description, isPublished, educationProgramId } = parsed.data;
  if (educationProgramId) {
    const [program] = await query(`SELECT id FROM education_programs WHERE id = ? LIMIT 1`, [educationProgramId]);
    if (!program) return res.status(400).json({ error: 'Eğitim bulunamadı' });
  }
  const result = await query(
    `UPDATE modules SET title = COALESCE(?, title), description = COALESCE(?, description),
       is_published = COALESCE(?, is_published),
       education_program_id = CASE WHEN ? THEN ? ELSE education_program_id END
     WHERE id = ?`,
    [
      title ?? null,
      description ?? null,
      isPublished === undefined ? null : isPublished ? 1 : 0,
      educationProgramId ? 1 : 0,
      educationProgramId ?? null,
      req.params.id,
    ]
  );
  if (!result.affectedRows) return res.status(404).json({ error: 'Not found' });
  await auditLog({ actorUserId: req.user.id, action: 'module.update', targetType: 'module', targetId: req.params.id, ip: req.ip });
  return res.json({ ok: true });
});

router.delete('/modules/:id', async (req, res) => {
  const videos = await query(`SELECT bunny_video_id AS guid FROM videos WHERE module_id = ?`, [req.params.id]);
  const result = await query(`DELETE FROM modules WHERE id = ?`, [req.params.id]);
  if (!result.affectedRows) return res.status(404).json({ error: 'Not found' });
  await Promise.all(videos.map((v) => deleteStreamVideo(v.guid)));
  await auditLog({
    actorUserId: req.user.id,
    action: 'module.delete',
    targetType: 'module',
    targetId: req.params.id,
    metadata: { videos: videos.length },
    ip: req.ip,
  });
  return res.json({ ok: true });
});

router.get('/modules/:id/videos', async (req, res) => {
  let rows = await query(`SELECT * FROM videos WHERE module_id = ? ORDER BY sort_order, video_number`, [req.params.id]);
  rows = await refreshStaleProcessing(rows);
  return res.json({ videos: rows.map((r) => videoDTO(r)) });
});

/** Creates the video record on Bunny and returns resumable-upload credentials for the device. */
router.post('/modules/:id/videos', async (req, res) => {
  if (!isStreamConfigured()) return res.status(503).json({ error: 'Video service not configured' });
  const parsed = videoSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'Invalid input' });

  const modules = await query(`SELECT id, title FROM modules WHERE id = ? LIMIT 1`, [req.params.id]);
  if (!modules.length) return res.status(404).json({ error: 'Not found' });

  const [{ next }] = await query(
    `SELECT COALESCE(MAX(video_number), 0) + 1 AS next FROM videos WHERE module_id = ?`,
    [req.params.id]
  );
  const guid = await createStreamVideo(`${modules[0].title} — ${parsed.data.title}`);
  const id = uuidv4();
  await query(
    `INSERT INTO videos (id, module_id, video_number, title, description, bunny_video_id, status, sort_order, is_published, allow_trial, uploaded_by_user_id)
     VALUES (?, ?, ?, ?, ?, ?, 'awaiting_upload', ?, ?, ?, ?)`,
    [
      id,
      req.params.id,
      next,
      parsed.data.title,
      parsed.data.description ?? null,
      guid,
      Number(next),
      parsed.data.isPublished === false ? 0 : 1,
      parsed.data.allowTrial ? 1 : 0,
      req.user.id,
    ]
  );
  await auditLog({ actorUserId: req.user.id, action: 'video.create', targetType: 'video', targetId: id, ip: req.ip });
  const [row] = await query(`SELECT * FROM videos WHERE id = ?`, [id]);
  return res.status(201).json({ video: videoDTO(row), upload: tusCredentials(guid) });
});

/** Fresh credentials to resume an interrupted upload. */
router.post('/videos/:id/upload-credentials', async (req, res) => {
  if (!isStreamConfigured()) return res.status(503).json({ error: 'Video service not configured' });
  const [row] = await query(`SELECT bunny_video_id AS guid FROM videos WHERE id = ?`, [req.params.id]);
  if (!row?.guid) return res.status(404).json({ error: 'Not found' });
  return res.json({ upload: tusCredentials(row.guid) });
});

router.post('/videos/:id/uploaded', async (req, res) => {
  await query(`UPDATE videos SET status = 'processing' WHERE id = ? AND status = 'awaiting_upload'`, [req.params.id]);
  const [row] = await query(`SELECT * FROM videos WHERE id = ?`, [req.params.id]);
  if (!row) return res.status(404).json({ error: 'Not found' });
  return res.json({ video: videoDTO(row) });
});

router.get('/videos/:id', async (req, res) => {
  const [row] = await query(`SELECT * FROM videos WHERE id = ?`, [req.params.id]);
  if (!row) return res.status(404).json({ error: 'Not found' });
  const synced = row.status === 'processing' ? await syncVideoFromBunny(row).catch(() => row) : row;
  return res.json({ video: videoDTO(synced) });
});

router.patch('/videos/:id', async (req, res) => {
  const parsed = videoSchema.partial().safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'Invalid input' });
  const { title, description, isPublished, allowTrial } = parsed.data;
  const result = await query(
    `UPDATE videos SET title = COALESCE(?, title), description = COALESCE(?, description),
       is_published = COALESCE(?, is_published), allow_trial = COALESCE(?, allow_trial) WHERE id = ?`,
    [
      title ?? null,
      description ?? null,
      isPublished === undefined ? null : isPublished ? 1 : 0,
      allowTrial === undefined ? null : allowTrial ? 1 : 0,
      req.params.id,
    ]
  );
  if (!result.affectedRows) return res.status(404).json({ error: 'Not found' });
  await auditLog({ actorUserId: req.user.id, action: 'video.update', targetType: 'video', targetId: req.params.id, ip: req.ip });
  return res.json({ ok: true });
});

router.delete('/videos/:id', async (req, res) => {
  const [row] = await query(`SELECT bunny_video_id AS guid FROM videos WHERE id = ?`, [req.params.id]);
  if (!row) return res.status(404).json({ error: 'Not found' });
  await query(`DELETE FROM videos WHERE id = ?`, [req.params.id]);
  if (row.guid) await deleteStreamVideo(row.guid);
  await auditLog({ actorUserId: req.user.id, action: 'video.delete', targetType: 'video', targetId: req.params.id, ip: req.ip });
  return res.json({ ok: true });
});

export default router;
