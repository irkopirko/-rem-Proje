import { Router } from 'express';
import { z } from 'zod';
import { v4 as uuidv4 } from 'uuid';
import { query } from '../db.js';
import { requireAuth, requireStudent } from '../middleware/auth.js';
import { attachImages } from '../services/contentImages.js';
import { isStreamConfigured, streamPlaybackUrl } from '../services/bunny.js';
import { videoDTO } from '../services/videoCatalog.js';

const router = Router();
router.use(requireAuth);

const PLAYABLE = `v.is_published = 1 AND v.status = 'ready'`;
const BLOCKED_MEMBERSHIPS = new Set(['trial_expired', 'none']);

function canWatch(user) {
  if (user.role === 'crew' || user.role === 'super_admin') return true;
  return !BLOCKED_MEMBERSHIPS.has(user.membership_status);
}

/** Lightweight catalogue: module list + counts; videos are loaded per module on demand. */
router.get('/modules', async (req, res) => {
  const rows = await query(
    `SELECT m.id, m.module_number, m.title, m.description, m.sort_order,
            (SELECT COUNT(*) FROM videos v WHERE v.module_id = m.id AND ${PLAYABLE}) AS video_count,
            (SELECT COUNT(*) FROM videos v JOIN video_progress vp ON vp.video_id = v.id
               WHERE v.module_id = m.id AND ${PLAYABLE} AND vp.user_id = ? AND vp.completed = 1) AS completed_count
     FROM modules m WHERE m.is_published = 1 ORDER BY m.sort_order, m.module_number`,
    [req.user.id]
  );
  const modules = rows.map((m) => ({
    id: m.id,
    moduleNumber: Number(m.module_number),
    title: m.title,
    description: m.description,
    sortOrder: m.sort_order,
    videoCount: Number(m.video_count),
    completedCount: Number(m.completed_count),
  }));

  // "Bugünün görevi": the first playable video the student has not finished yet.
  const [next] = await query(
    `SELECT v.* FROM videos v
     JOIN modules m ON m.id = v.module_id AND m.is_published = 1
     LEFT JOIN video_progress vp ON vp.video_id = v.id AND vp.user_id = ?
     WHERE ${PLAYABLE} AND (vp.completed IS NULL OR vp.completed = 0)
     ORDER BY m.sort_order, m.module_number, v.sort_order, v.video_number LIMIT 1`,
    [req.user.id]
  );

  const live = await query(
    `SELECT id, title, stream_url AS streamUrl, thumbnail_url AS thumbnailUrl, starts_at AS startsAt
     FROM live_sessions WHERE is_active = 1 AND starts_at <= UTC_TIMESTAMP()
       AND (ends_at IS NULL OR ends_at >= UTC_TIMESTAMP())
     ORDER BY starts_at DESC LIMIT 1`
  );
  return res.json({ modules, nextVideo: next ? videoDTO(next) : null, liveSession: live[0] ?? null });
});

router.get('/modules/:id/videos', async (req, res) => {
  const rows = await query(
    `SELECT v.*, vp.completed, vp.last_position_seconds
     FROM videos v
     JOIN modules m ON m.id = v.module_id AND m.is_published = 1
     LEFT JOIN video_progress vp ON vp.video_id = v.id AND vp.user_id = ?
     WHERE v.module_id = ? AND ${PLAYABLE}
     ORDER BY v.sort_order, v.video_number`,
    [req.user.id, req.params.id]
  );
  return res.json({ videos: rows.map((r) => videoDTO(r, r)) });
});

/** Short-lived signed HLS URL; the CDN rejects the stream once it expires. */
router.get('/videos/:id/playback', async (req, res) => {
  if (!canWatch(req.user)) return res.status(402).json({ error: 'Membership required' });
  if (!isStreamConfigured()) return res.status(503).json({ error: 'Video service not configured' });

  const [row] = await query(
    `SELECT v.*, vp.completed, vp.last_position_seconds FROM videos v
     LEFT JOIN video_progress vp ON vp.video_id = v.id AND vp.user_id = ?
     WHERE v.id = ? LIMIT 1`,
    [req.user.id, req.params.id]
  );
  const isStaff = req.user.role !== 'student';
  if (!row || !row.bunny_video_id || row.status !== 'ready' || (!row.is_published && !isStaff)) {
    return res.status(404).json({ error: 'Not found' });
  }
  const playback = streamPlaybackUrl(row.bunny_video_id);
  return res.json({
    video: videoDTO(row, row),
    hlsUrl: playback.url,
    expiresAt: playback.expiresAt,
  });
});

router.post('/videos/:id/progress', requireStudent, async (req, res) => {
  const schema = z.object({
    lastPositionSeconds: z.number().int().min(0),
    watchedSeconds: z.number().int().min(0),
    completed: z.boolean().optional(),
  });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'Invalid input' });

  await query(
    `INSERT INTO video_progress (user_id, video_id, watched_seconds, last_position_seconds, completed)
     VALUES (?, ?, ?, ?, ?)
     ON DUPLICATE KEY UPDATE
       watched_seconds = GREATEST(watched_seconds, VALUES(watched_seconds)),
       last_position_seconds = VALUES(last_position_seconds),
       completed = GREATEST(completed, VALUES(completed))`,
    [
      req.user.id,
      req.params.id,
      parsed.data.watchedSeconds,
      parsed.data.lastPositionSeconds,
      parsed.data.completed ? 1 : 0,
    ]
  );
  return res.json({ ok: true });
});

router.get('/products', async (req, res) => {
  const categories = await query(
    `SELECT id, name, image_url AS imageUrl, sort_order AS sortOrder
     FROM product_categories WHERE is_published = 1 ORDER BY sort_order`
  );
  const products = await query(
    `SELECT id, category_id AS categoryId, name, image_url AS imageUrl, explanation, purchase_url AS purchaseUrl
     FROM products WHERE is_published = 1 ORDER BY sort_order`
  );
  return res.json({ categories, products: await attachImages('product', products) });
});

router.get('/homework', requireStudent, async (req, res) => {
  const rows = await query(
    `SELECT ha.id AS assignmentId, h.id AS homeworkId, h.title, h.explanation, h.due_at AS dueAt, ha.status,
            (SELECT score FROM homework_grades hg WHERE hg.assignment_id = ha.id AND hg.is_revision_grade = 0 ORDER BY graded_at DESC LIMIT 1) AS primaryScore,
            (SELECT score FROM homework_grades hg WHERE hg.assignment_id = ha.id ORDER BY graded_at DESC LIMIT 1) AS latestScore
     FROM homework_assignments ha
     JOIN homework h ON h.id = ha.homework_id
     WHERE ha.student_id = ? AND h.is_published = 1
     ORDER BY ha.assigned_at DESC`,
    [req.user.id]
  );
  return res.json({ assignments: await attachImages('homework', rows, 'homeworkId') });
});

router.post('/homework/:assignmentId/submit', requireStudent, async (req, res) => {
  const schema = z.object({
    fileUrl: z.string().url(),
    fileMime: z.enum(['application/pdf', 'image/jpeg', 'image/jpg', 'image/png']),
  });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'Invalid file' });

  const rows = await query(
    `SELECT id, status FROM homework_assignments WHERE id = ? AND student_id = ?`,
    [req.params.assignmentId, req.user.id]
  );
  if (!rows.length) return res.status(404).json({ error: 'Not found' });
  if (rows[0].status === 'graded_pass') {
    return res.status(400).json({ error: 'Assignment already passed' });
  }

  await query(
    `INSERT INTO homework_submissions (id, assignment_id, file_url, file_mime) VALUES (?, ?, ?, ?)`,
    [uuidv4(), req.params.assignmentId, parsed.data.fileUrl, parsed.data.fileMime]
  );
  await query(`UPDATE homework_assignments SET status = 'submitted' WHERE id = ?`, [
    req.params.assignmentId,
  ]);
  return res.json({ ok: true });
});

router.get('/badges', requireStudent, async (req, res) => {
  const all = await query(`SELECT id, slug, title, image_url AS imageUrl FROM badges ORDER BY sort_order`);
  const earned = await query(
    `SELECT badge_id AS badgeId, earned_at AS earnedAt FROM user_badges WHERE user_id = ?`,
    [req.user.id]
  );
  return res.json({ badges: all, earned });
});

router.get('/guide', async (_req, res) => {
  const rows = await query(`SELECT content_value FROM app_content WHERE content_key = 'guide_pdf_url'`);
  return res.json({ pdfUrl: rows[0]?.content_value ?? null });
});

export default router;
