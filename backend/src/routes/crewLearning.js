import { Router } from 'express';
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

const router = Router();
router.use(requireAuth, requireCrew);

const moduleSchema = z.object({
  title: z.string().trim().min(1).max(255),
  description: z.string().trim().max(10000).optional(),
  isPublished: z.boolean().optional(),
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
    moduleNumber: Number(row.module_number),
    title: row.title,
    description: row.description,
    sortOrder: row.sort_order,
    isPublished: Boolean(row.is_published),
    videoCount: Number(row.video_count ?? 0),
    readyCount: Number(row.ready_count ?? 0),
  };
}

router.get('/modules', async (_req, res) => {
  const rows = await query(
    `SELECT m.*,
            (SELECT COUNT(*) FROM videos v WHERE v.module_id = m.id) AS video_count,
            (SELECT COUNT(*) FROM videos v WHERE v.module_id = m.id AND v.status = 'ready') AS ready_count
     FROM modules m ORDER BY m.sort_order, m.module_number`
  );
  return res.json({ modules: rows.map(moduleDTO), videoServiceConfigured: isStreamConfigured() });
});

router.post('/modules', async (req, res) => {
  const parsed = moduleSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'Invalid input' });
  const [{ next }] = await query(`SELECT COALESCE(MAX(module_number), 0) + 1 AS next FROM modules`);
  const id = uuidv4();
  await query(
    `INSERT INTO modules (id, module_number, title, description, sort_order, is_published) VALUES (?, ?, ?, ?, ?, ?)`,
    [id, next, parsed.data.title, parsed.data.description ?? null, Number(next), parsed.data.isPublished === false ? 0 : 1]
  );
  await auditLog({ actorUserId: req.user.id, action: 'module.create', targetType: 'module', targetId: id, ip: req.ip });
  const [row] = await query(`SELECT * FROM modules WHERE id = ?`, [id]);
  return res.status(201).json({ id, module: moduleDTO(row) });
});

router.patch('/modules/:id', async (req, res) => {
  const parsed = moduleSchema.partial().safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'Invalid input' });
  const { title, description, isPublished } = parsed.data;
  const result = await query(
    `UPDATE modules SET title = COALESCE(?, title), description = COALESCE(?, description),
       is_published = COALESCE(?, is_published) WHERE id = ?`,
    [title ?? null, description ?? null, isPublished === undefined ? null : isPublished ? 1 : 0, req.params.id]
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
