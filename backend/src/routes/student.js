import express, { Router } from 'express';
import { z } from 'zod';
import { query } from '../db.js';
import { requireAuth, requireStudent } from '../middleware/auth.js';
import { attachImages } from '../services/contentImages.js';
import { isStreamConfigured, streamEmbedUrl, streamPlaybackUrl } from '../services/bunny.js';
import { ensurePlayable, refreshStaleProcessing, videoDTO } from '../services/videoCatalog.js';
import { canSeeHomework, canSeeHomeworkItem, canWatchVideo, studentHomeworkCatalogSql, studentVideoAccessSql, studentVideoCatalogSql } from '../services/membership.js';
import { guideForStudent } from '../services/guide.js';
import { applyDisplayLabels, programDTO } from '../services/programs.js';
import {
  MAX_HOMEWORK_PROXY_BYTES,
  assignmentFileBytes,
  beginHomeworkFileUpload,
  confirmHomeworkFile,
  listHomeworkFilesByAssignments,
  storeHomeworkSubmission,
} from '../services/homeworkSubmissions.js';
import {
  evaluateBadges,
  grantXp,
  progressFor,
  quietEvaluate,
  recordVideoDay,
  recordWeeklyGameWin,
  XP_PER_HOMEWORK_SUBMIT,
  XP_PER_VIDEO,
} from '../services/badges.js';

const router = Router();
router.use(requireAuth);

const PLAYABLE = `v.is_published = 1 AND v.status = 'ready'`;

function isHomeworkOverdue(dueAt) {
  if (!dueAt) return false;
  const due = dueAt instanceof Date ? dueAt : new Date(dueAt);
  if (Number.isNaN(due.getTime())) return false;
  return due.getTime() < Date.now();
}

function catalogVideos(user) {
  return `${PLAYABLE} AND ${studentVideoCatalogSql(user, 'v')}`;
}

function playableVideos(user) {
  return `${PLAYABLE} AND ${studentVideoAccessSql(user, 'v')}`;
}

function studentModuleWhere() {
  return `m.is_published = 1 AND (m.education_program_id IS NULL OR p.is_published = 1)`;
}

function mapStudentModule(row) {
  return {
    id: row.id,
    educationProgramId: row.education_program_id ?? null,
    moduleNumber: Number(row.module_number),
    title: row.title,
    description: row.description,
    sortOrder: Number(row.sort_order || 0),
    videoCount: Number(row.video_count || 0),
    completedCount: Number(row.completed_count || 0),
    displayLabel: row.displayLabel || null,
  };
}

router.get('/programs', async (req, res) => {
  const programs = await query(
    `SELECT p.*,
            (SELECT COUNT(*) FROM modules m WHERE m.education_program_id = p.id AND m.is_published = 1) AS moduleCount,
            (SELECT COUNT(*) FROM videos v JOIN modules m ON m.id = v.module_id
              WHERE m.education_program_id = p.id AND m.is_published = 1 AND ${catalogVideos(req.user)}) AS videoCount,
            (SELECT COUNT(*) FROM videos v JOIN modules m ON m.id = v.module_id
              JOIN video_progress vp ON vp.video_id = v.id AND vp.user_id = ? AND vp.completed = 1
              WHERE m.education_program_id = p.id AND m.is_published = 1 AND ${catalogVideos(req.user)}) AS completedCount
     FROM education_programs p
     WHERE p.is_published = 1
     ORDER BY p.sort_order, p.title`,
    [req.user.id]
  );
  const labeled = applyDisplayLabels(programs, []).programs;
  return res.json({ programs: labeled.map((row) => programDTO(row)) });
});

router.get('/programs/:id', async (req, res) => {
  const [program] = await query(
    `SELECT p.*,
            (SELECT COUNT(*) FROM modules m WHERE m.education_program_id = p.id AND m.is_published = 1) AS moduleCount,
            (SELECT COUNT(*) FROM videos v JOIN modules m ON m.id = v.module_id
              WHERE m.education_program_id = p.id AND m.is_published = 1 AND ${catalogVideos(req.user)}) AS videoCount,
            (SELECT COUNT(*) FROM videos v JOIN modules m ON m.id = v.module_id
              JOIN video_progress vp ON vp.video_id = v.id AND vp.user_id = ? AND vp.completed = 1
              WHERE m.education_program_id = p.id AND m.is_published = 1 AND ${catalogVideos(req.user)}) AS completedCount
     FROM education_programs p WHERE p.id = ? AND p.is_published = 1 LIMIT 1`,
    [req.user.id, req.params.id]
  );
  if (!program) return res.status(404).json({ error: 'Not found' });
  const rows = await query(
    `SELECT m.id, m.education_program_id, m.module_number, m.title, m.description, m.sort_order,
            (SELECT COUNT(*) FROM videos v WHERE v.module_id = m.id AND ${catalogVideos(req.user)}) AS video_count,
            (SELECT COUNT(*) FROM videos v JOIN video_progress vp ON vp.video_id = v.id
               WHERE v.module_id = m.id AND ${catalogVideos(req.user)} AND vp.user_id = ? AND vp.completed = 1) AS completed_count
     FROM modules m
     WHERE m.education_program_id = ? AND m.is_published = 1
     ORDER BY m.sort_order, m.module_number`,
    [req.user.id, req.params.id]
  );
  const labeled = applyDisplayLabels([program], rows);
  return res.json({
    program: programDTO(labeled.programs[0]),
    modules: labeled.modules.map(mapStudentModule),
  });
});

/** Lightweight catalogue: module list + counts; videos are loaded per module on demand. */
router.get('/modules', async (req, res) => {
  const programRows = await query(`SELECT * FROM education_programs ORDER BY sort_order, title`);
  const rows = await query(
    `SELECT m.id, m.education_program_id, m.module_number, m.title, m.description, m.sort_order,
            (SELECT COUNT(*) FROM videos v WHERE v.module_id = m.id AND ${catalogVideos(req.user)}) AS video_count,
            (SELECT COUNT(*) FROM videos v JOIN video_progress vp ON vp.video_id = v.id
               WHERE v.module_id = m.id AND ${catalogVideos(req.user)} AND vp.user_id = ? AND vp.completed = 1) AS completed_count
     FROM modules m
     LEFT JOIN education_programs p ON p.id = m.education_program_id
     WHERE ${studentModuleWhere()}
     ORDER BY COALESCE(p.sort_order, 999), m.sort_order, m.module_number`,
    [req.user.id]
  );
  const labeled = applyDisplayLabels(programRows, rows);
  const modules = labeled.modules.map(mapStudentModule);

  // "Bugünün görevi": the first playable video the student has not finished yet.
  const [next] = await query(
    `SELECT v.* FROM videos v
     JOIN modules m ON m.id = v.module_id AND m.is_published = 1
     LEFT JOIN education_programs p ON p.id = m.education_program_id
     LEFT JOIN video_progress vp ON vp.video_id = v.id AND vp.user_id = ?
     WHERE ${playableVideos(req.user)} AND (m.education_program_id IS NULL OR p.is_published = 1)
       AND (vp.completed IS NULL OR vp.completed = 0)
     ORDER BY COALESCE(p.sort_order, 999), m.sort_order, m.module_number, v.sort_order, v.video_number LIMIT 1`,
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
  let rows = await query(
    `SELECT v.*, vp.completed, vp.last_position_seconds
     FROM videos v
     JOIN modules m ON m.id = v.module_id AND m.is_published = 1
     LEFT JOIN education_programs p ON p.id = m.education_program_id
     LEFT JOIN video_progress vp ON vp.video_id = v.id AND vp.user_id = ?
     WHERE v.module_id = ? AND ${catalogVideos(req.user)}
       AND (m.education_program_id IS NULL OR p.is_published = 1)
     ORDER BY v.sort_order, v.video_number`,
    [req.user.id, req.params.id]
  );
  rows = await refreshStaleProcessing(rows);
  return res.json({
    videos: rows.map((r) => ({ ...videoDTO(r, r), locked: !canWatchVideo(req.user, r) })),
  });
});

/** Short-lived signed HLS URL; the CDN rejects the stream once it expires. */
router.get('/videos/:id/playback', async (req, res) => {
  if (!isStreamConfigured()) return res.status(503).json({ error: 'Video service not configured' });

  const [found] = await query(
    `SELECT v.*, vp.completed, vp.last_position_seconds FROM videos v
     LEFT JOIN video_progress vp ON vp.video_id = v.id AND vp.user_id = ?
     WHERE v.id = ? LIMIT 1`,
    [req.user.id, req.params.id]
  );
  const row = await ensurePlayable(found);
  const isStaff = req.user.role !== 'student';
  if (!row || !row.bunny_video_id || (!row.is_published && !isStaff)) {
    return res.status(404).json({ error: 'Not found' });
  }
  if (row.status !== 'ready') {
    return res.status(409).json({ error: 'Video henüz işleniyor. Biraz sonra tekrar dene.' });
  }
  if (!canWatchVideo(req.user, row)) return res.status(402).json({ error: 'Membership required' });
  const playback = streamPlaybackUrl(row.bunny_video_id);
  const embed = streamEmbedUrl(row.bunny_video_id);
  return res.json({
    video: videoDTO(row, row),
    hlsUrl: playback.url,
    embedUrl: embed.url,
    expiresAt: embed.expiresAt,
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

  const [prev] = await query(`SELECT completed FROM video_progress WHERE user_id = ? AND video_id = ?`, [
    req.user.id,
    req.params.id,
  ]);
  const newlyCompleted = Boolean(parsed.data.completed) && !prev?.completed;

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
  if (newlyCompleted) {
    await recordVideoDay(req.user.id);
    await grantXp(req.user.id, XP_PER_VIDEO);
    await evaluateBadges(req.user.id);
  }
  return res.json({ ok: true });
});

router.get('/products', async (req, res) => {
  const categories = await query(
    `SELECT id, name, image_url AS imageUrl, sort_order AS sortOrder
     FROM product_categories WHERE is_published = 1 ORDER BY sort_order, name`
  );
  const products = await attachImages(
    'product',
    await query(
      `SELECT id, category_id AS categoryId, name, image_url AS imageUrl, explanation, purchase_url AS purchaseUrl
       FROM products WHERE is_published = 1 ORDER BY sort_order`
    )
  );
  const byCategory = new Map();
  for (const product of products) {
    const key = String(product.categoryId ?? '').trim();
    if (!byCategory.has(key)) byCategory.set(key, []);
    byCategory.get(key).push(product);
  }
  return res.json({
    categories: categories.map((category) => {
      const id = String(category.id ?? '').trim();
      return {
        id,
        name: category.name,
        imageUrl: category.imageUrl,
        sortOrder: category.sortOrder,
        products: byCategory.get(id) ?? [],
      };
    }),
    products,
  });
});

router.get('/homework', requireStudent, async (req, res) => {
  const rows = await query(
    `SELECT ha.id AS assignmentId, h.id AS homeworkId, h.title, h.explanation, h.due_at AS dueAt, ha.status,
            h.allow_trial AS allowTrial, h.allow_paid AS allowPaid,
            (SELECT score FROM homework_grades hg WHERE hg.assignment_id = ha.id AND hg.is_revision_grade = 0 ORDER BY graded_at DESC LIMIT 1) AS primaryScore,
            (SELECT score FROM homework_grades hg WHERE hg.assignment_id = ha.id ORDER BY graded_at DESC LIMIT 1) AS latestScore
     FROM homework_assignments ha
     JOIN homework h ON h.id = ha.homework_id
     WHERE ha.student_id = ? AND h.is_published = 1 AND ${studentHomeworkCatalogSql(req.user, 'h')}
     ORDER BY ha.assigned_at DESC`,
    [req.user.id]
  );
  const filesByAssignment = await listHomeworkFilesByAssignments(rows.map((row) => row.assignmentId));
  const withImages = await attachImages('homework', rows, 'homeworkId');
  return res.json({
    assignments: withImages.map((row) => {
      const allowTrial = Boolean(row.allowTrial);
      const allowPaid = row.allowPaid === undefined ? true : Boolean(row.allowPaid);
      const files = filesByAssignment.get(row.assignmentId) || [];
      return {
        ...row,
        allowTrial,
        allowPaid,
        locked: !canSeeHomeworkItem(req.user, { allowTrial, allowPaid }),
        overdue: isHomeworkOverdue(row.dueAt),
        files,
        fileUrl: files[0]?.url || null,
      };
    }),
  });
});

const rawHomeworkFile = express.raw({ type: () => true, limit: MAX_HOMEWORK_PROXY_BYTES });

function rawHomeworkIfBinary(req, res, next) {
  const type = String(req.headers['content-type'] || '').toLowerCase();
  if (!type || type.includes('application/json')) return next();
  return rawHomeworkFile(req, res, next);
}

async function loadStudentAssignment(req) {
  const rows = await query(
    `SELECT ha.id, ha.status, h.allow_trial AS allowTrial, h.allow_paid AS allowPaid, h.due_at AS dueAt
     FROM homework_assignments ha
     JOIN homework h ON h.id = ha.homework_id
     WHERE ha.id = ? AND ha.student_id = ?`,
    [req.params.assignmentId, req.user.id]
  );
  return rows[0] || null;
}

function uploadDenied(res, req, row) {
  if (!row) return res.status(404).json({ error: 'Not found' });
  if (!canSeeHomeworkItem(req.user, row)) return res.status(402).json({ error: 'Membership required' });
  if (row.status === 'graded_pass') return res.status(400).json({ error: 'Assignment already passed' });
  if (isHomeworkOverdue(row.dueAt)) {
    return res.status(400).json({ error: 'Teslim tarihi geçti. Bu ödeve artık yükleme yapılamaz.' });
  }
  if (row.status !== 'pending' && row.status !== 'graded_revise') {
    return res.status(400).json({ error: 'Bu ödeve şu anda dosya yüklenemez.' });
  }
  return null;
}

async function finalizeHomework(req, assignmentId) {
  const used = await assignmentFileBytes(assignmentId);
  if (used <= 0) return { status: 400, body: { error: 'En az bir dosya yüklemelisin.' } };
  await query(`UPDATE homework_assignments SET status = 'submitted' WHERE id = ?`, [assignmentId]);
  await grantXp(req.user.id, XP_PER_HOMEWORK_SUBMIT);
  await evaluateBadges(req.user.id);
  const files = (await listHomeworkFilesByAssignments([assignmentId])).get(assignmentId) || [];
  return { status: 200, body: { ok: true, fileUrl: files[0]?.url || null, files } };
}

router.post('/homework/:assignmentId/upload-session', requireStudent, async (req, res) => {
  const row = await loadStudentAssignment(req);
  const denied = uploadDenied(res, req, row);
  if (denied) return denied;
  const parsed = z
    .object({
      mimeType: z.string().min(1),
      size: z.number().int().positive(),
      name: z.string().max(180).optional(),
    })
    .safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'Invalid file' });
  const started = await beginHomeworkFileUpload(req.params.assignmentId, parsed.data);
  if (started.status !== 200) return res.status(started.status).json(started.body);
  return res.json({ upload: started.upload });
});

router.post('/homework/:assignmentId/files', requireStudent, rawHomeworkIfBinary, async (req, res) => {
  const row = await loadStudentAssignment(req);
  const denied = uploadDenied(res, req, row);
  if (denied) return denied;

  if (Buffer.isBuffer(req.body) && req.body.length) {
    const stored = await storeHomeworkSubmission(req.params.assignmentId, req.body);
    if (stored.status !== 200) return res.status(stored.status).json(stored.body);
    return res.json({ ok: true, fileUrl: stored.url, id: stored.id });
  }

  const parsed = z
    .object({
      key: z.string().min(1),
      mimeType: z.string().min(1),
      size: z.number().int().positive(),
      name: z.string().max(180).optional(),
    })
    .safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'Invalid file' });
  const stored = await confirmHomeworkFile(req.params.assignmentId, parsed.data);
  if (stored.status !== 200) return res.status(stored.status).json(stored.body);
  return res.json({ ok: true, fileUrl: stored.url, id: stored.id });
});

router.post('/homework/:assignmentId/submit', requireStudent, rawHomeworkIfBinary, async (req, res) => {
  const row = await loadStudentAssignment(req);
  const denied = uploadDenied(res, req, row);
  if (denied) return denied;

  if (Buffer.isBuffer(req.body) && req.body.length) {
    const stored = await storeHomeworkSubmission(req.params.assignmentId, req.body);
    if (stored.status !== 200) return res.status(stored.status).json(stored.body);
  }

  const result = await finalizeHomework(req, req.params.assignmentId);
  return res.status(result.status).json(result.body);
});

router.get('/badges', requireStudent, async (req, res) => {
  return res.json(await progressFor(req.user.id));
});

router.post('/game/weekly-complete', requireStudent, async (req, res) => {
  const firstToday = await recordWeeklyGameWin(req.user.id);
  if (!firstToday) {
    const progress = await progressFor(req.user.id);
    return res.status(409).json({ error: 'Bugün zaten oynadın.', ...progress });
  }
  return res.json(await progressFor(req.user.id));
});

router.get('/guide', async (req, res) => {
  if (!canSeeHomework(req.user)) return res.status(402).json({ error: 'Membership required' });
  return res.json(await guideForStudent());
});

export default router;
