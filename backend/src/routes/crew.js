import express, { Router } from 'express';
import { z } from 'zod';
import { v4 as uuidv4 } from 'uuid';
import { query } from '../db.js';
import { requireAuth, requireCrew } from '../middleware/auth.js';
import { hashPassword } from '../utils/crypto.js';
import { auditLog } from '../services/audit.js';
import { quietEvaluate } from '../services/badges.js';
import {
  MAX_IMAGE_BYTES,
  attachImages,
  deleteImage,
  deleteImagesForOwners,
  storeImage,
} from '../services/contentImages.js';
import { beginGuideUpload, confirmGuideUpload, guideForCrew } from '../services/guide.js';

const rawImage = express.raw({ type: () => true, limit: MAX_IMAGE_BYTES });

const router = Router();
router.use(requireAuth, requireCrew);

router.get('/students', async (_req, res) => {
  const students = await query(
    `SELECT id, user_no AS userNo, username, first_name AS firstName, last_name AS lastName,
            membership_status AS membershipStatus, chat_banned AS chatBanned, created_at AS createdAt
     FROM users WHERE role = 'student' AND deleted_at IS NULL
     ORDER BY user_no ASC`
  );
  return res.json({ students: students.map((s) => ({ ...s, chatBanned: Boolean(s.chatBanned) })) });
});

router.get('/students/:id', async (req, res) => {
  const rows = await query(
    `SELECT id, user_no AS userNo, username, first_name AS firstName, last_name AS lastName,
            membership_status AS membershipStatus, profile_photo_url AS profilePhotoUrl
     FROM users WHERE id = ? AND role = 'student' LIMIT 1`,
    [req.params.id]
  );
  if (!rows.length) return res.status(404).json({ error: 'Not found' });

  const progress = await query(
    `SELECT v.title, v.video_number AS videoNumber, vp.completed, vp.last_position_seconds AS lastPosition
     FROM video_progress vp
     JOIN videos v ON v.id = vp.video_id
     WHERE vp.user_id = ?
     ORDER BY v.video_number`,
    [req.params.id]
  );
  const badges = await query(
    `SELECT b.title, ub.earned_at AS earnedAt FROM user_badges ub
     JOIN badges b ON b.id = ub.badge_id WHERE ub.user_id = ?`,
    [req.params.id]
  );
  return res.json({
    student: rows[0],
    videoProgress: progress.map((p) => ({ ...p, videoNumber: Number(p.videoNumber), completed: Boolean(p.completed) })),
    badges,
  });
});

const homeworkSchema = z.object({
  title: z.string().trim().min(1).max(255),
  explanation: z.string().trim().min(1).max(10000),
  dueAt: z.string().datetime().nullable().optional(),
  allowTrial: z.boolean().optional(),
  allowPaid: z.boolean().optional(),
  // Omitted → every active student (and students who join later) gets the homework.
  studentIds: z.array(z.string().uuid()).min(1).optional(),
});

router.get('/homework', async (_req, res) => {
  const rows = await query(
    `SELECT h.id, h.title, h.explanation, h.due_at AS dueAt, h.assign_to_all AS assignToAll,
            h.allow_trial AS allowTrial, h.allow_paid AS allowPaid, h.created_at AS createdAt,
            (SELECT COUNT(*) FROM homework_assignments ha WHERE ha.homework_id = h.id) AS assignedCount,
            (SELECT COUNT(*) FROM homework_assignments ha WHERE ha.homework_id = h.id
               AND ha.status IN ('submitted','grading','graded_pass','graded_revise')) AS submittedCount
     FROM homework h ORDER BY h.created_at DESC`
  );
  const homework = rows.map((r) => ({
    ...r,
    assignToAll: Boolean(r.assignToAll),
    allowTrial: Boolean(r.allowTrial),
    allowPaid: r.allowPaid !== 0,
  }));
  return res.json({ homework: await attachImages('homework', homework) });
});

router.post('/homework', async (req, res) => {
  const parsed = homeworkSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'Invalid input' });
  const { title, explanation, dueAt, studentIds, allowTrial, allowPaid } = parsed.data;
  const assignToAll = !studentIds;
  const homeworkId = uuidv4();
  await query(
    `INSERT INTO homework (id, title, explanation, created_by, due_at, assign_to_all, allow_trial, allow_paid)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
    [
      homeworkId,
      title,
      explanation,
      req.user.id,
      dueAt ? new Date(dueAt) : null,
      assignToAll ? 1 : 0,
      allowTrial ? 1 : 0,
      allowPaid === false ? 0 : 1,
    ]
  );

  const targets = assignToAll
    ? (await query(`SELECT id FROM users WHERE role = 'student' AND deleted_at IS NULL`)).map((r) => r.id)
    : studentIds;
  for (const studentId of targets) {
    await query(
      `INSERT IGNORE INTO homework_assignments (id, homework_id, student_id) VALUES (?, ?, ?)`,
      [uuidv4(), homeworkId, studentId]
    );
  }
  await auditLog({ actorUserId: req.user.id, action: 'homework.create', targetType: 'homework', targetId: homeworkId, metadata: { assigned: targets.length }, ip: req.ip });
  return res.status(201).json({ id: homeworkId });
});

router.patch('/homework/:id', async (req, res) => {
  const parsed = homeworkSchema.omit({ studentIds: true }).partial().safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'Invalid input' });
  const { title, explanation, dueAt, allowTrial, allowPaid } = parsed.data;
  const result = await query(
    `UPDATE homework SET
       title = COALESCE(?, title),
       explanation = COALESCE(?, explanation),
       due_at = IF(?, ?, due_at),
       allow_trial = COALESCE(?, allow_trial),
       allow_paid = COALESCE(?, allow_paid)
     WHERE id = ?`,
    [
      title ?? null,
      explanation ?? null,
      dueAt !== undefined ? 1 : 0,
      dueAt ? new Date(dueAt) : null,
      allowTrial === undefined ? null : allowTrial ? 1 : 0,
      allowPaid === undefined ? null : allowPaid ? 1 : 0,
      req.params.id,
    ]
  );
  if (!result.affectedRows) return res.status(404).json({ error: 'Not found' });
  await auditLog({ actorUserId: req.user.id, action: 'homework.update', targetType: 'homework', targetId: req.params.id, ip: req.ip });
  return res.json({ ok: true });
});

router.delete('/homework/:id', async (req, res) => {
  await deleteImagesForOwners('homework', [req.params.id]);
  await query(`DELETE FROM homework WHERE id = ?`, [req.params.id]);
  await auditLog({ actorUserId: req.user.id, action: 'homework.delete', targetType: 'homework', targetId: req.params.id, ip: req.ip });
  return res.json({ ok: true });
});

router.post('/homework/:id/images', rawImage, async (req, res) => {
  const result = await storeImage('homework', req.params.id, req.body, req.user.id);
  return res.status(result.status).json(result.body);
});

router.delete('/homework/images/:imageId', async (req, res) => {
  await deleteImage('homework', req.params.imageId);
  return res.json({ ok: true });
});

router.get('/homework/pending-review', async (_req, res) => {
  const rows = await query(
    `SELECT ha.id AS assignmentId, h.title, u.first_name AS firstName, u.last_name AS lastName, ha.status,
            (SELECT file_url FROM homework_submissions hs WHERE hs.assignment_id = ha.id ORDER BY submitted_at DESC LIMIT 1) AS fileUrl
     FROM homework_assignments ha
     JOIN homework h ON h.id = ha.homework_id
     JOIN users u ON u.id = ha.student_id
     WHERE ha.status IN ('submitted','grading')
     ORDER BY ha.assigned_at ASC`
  );
  return res.json({ items: rows });
});

router.post('/homework/:assignmentId/grade', async (req, res) => {
  const schema = z.object({
    score: z.number().int().min(0).max(100),
    feedback: z.string().optional(),
    requestRevision: z.boolean().optional(),
  });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'Invalid input' });

  const assignmentRows = await query(`SELECT status, student_id AS studentId FROM homework_assignments WHERE id = ?`, [
    req.params.assignmentId,
  ]);
  if (!assignmentRows.length) return res.status(404).json({ error: 'Not found' });

  const isRevision =
    assignmentRows[0].status === 'graded_revise' || parsed.data.requestRevision === true;
  const pass = parsed.data.score >= 100 && !parsed.data.requestRevision;

  await query(
    `INSERT INTO homework_grades (id, assignment_id, score, feedback, graded_by, is_revision_grade)
     VALUES (?, ?, ?, ?, ?, ?)`,
    [
      uuidv4(),
      req.params.assignmentId,
      parsed.data.score,
      parsed.data.feedback ?? null,
      req.user.id,
      isRevision ? 1 : 0,
    ]
  );

  const newStatus = pass ? 'graded_pass' : parsed.data.requestRevision ? 'graded_revise' : 'grading';
  await query(`UPDATE homework_assignments SET status = ? WHERE id = ?`, [
    newStatus,
    req.params.assignmentId,
  ]);
  quietEvaluate(assignmentRows[0].studentId);
  return res.json({ ok: true, status: newStatus });
});

router.post('/products/category', async (req, res) => {
  const schema = z.object({
    name: z.string().min(1),
    imageUrl: z.string().url().optional(),
  });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'Invalid input' });
  const id = uuidv4();
  await query(`INSERT INTO product_categories (id, name, image_url) VALUES (?, ?, ?)`, [
    id,
    parsed.data.name,
    parsed.data.imageUrl ?? null,
  ]);
  return res.status(201).json({ id });
});

router.delete('/products/category/:id', async (req, res) => {
  const products = await query(`SELECT id FROM products WHERE category_id = ?`, [req.params.id]);
  await deleteImagesForOwners('product', products.map((p) => p.id));
  await query(`DELETE FROM product_categories WHERE id = ?`, [req.params.id]);
  await auditLog({ actorUserId: req.user.id, action: 'product_category.delete', targetType: 'product_category', targetId: req.params.id, ip: req.ip });
  return res.json({ ok: true });
});

router.get('/products', async (_req, res) => {
  const categories = await query(
    `SELECT id, name, image_url AS imageUrl, sort_order AS sortOrder
     FROM product_categories ORDER BY sort_order, name`
  );
  const products = await query(
    `SELECT id, category_id AS categoryId, name, image_url AS imageUrl, explanation,
            purchase_url AS purchaseUrl, is_published AS isPublished
     FROM products ORDER BY sort_order, name`
  );
  const normalized = products.map((p) => ({ ...p, isPublished: Boolean(p.isPublished) }));
  return res.json({ categories, products: await attachImages('product', normalized) });
});

const productSchema = z.object({
  categoryId: z.string().uuid(),
  name: z.string().trim().min(1).max(255),
  explanation: z.string().trim().max(5000).optional(),
  purchaseUrl: z.string().url().refine((u) => u.startsWith('https://'), 'https only'),
});

router.post('/products', async (req, res) => {
  const parsed = productSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'Invalid input' });
  const id = uuidv4();
  await query(
    `INSERT INTO products (id, category_id, name, explanation, purchase_url)
     VALUES (?, ?, ?, ?, ?)`,
    [id, parsed.data.categoryId, parsed.data.name, parsed.data.explanation ?? null, parsed.data.purchaseUrl]
  );
  await auditLog({ actorUserId: req.user.id, action: 'product.create', targetType: 'product', targetId: id, ip: req.ip });
  return res.status(201).json({ id });
});

router.patch('/products/:id', async (req, res) => {
  const parsed = productSchema.partial().safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'Invalid input' });
  const { categoryId, name, explanation, purchaseUrl } = parsed.data;
  const result = await query(
    `UPDATE products SET
       category_id = COALESCE(?, category_id),
       name = COALESCE(?, name),
       explanation = COALESCE(?, explanation),
       purchase_url = COALESCE(?, purchase_url)
     WHERE id = ?`,
    [categoryId ?? null, name ?? null, explanation ?? null, purchaseUrl ?? null, req.params.id]
  );
  if (!result.affectedRows) return res.status(404).json({ error: 'Not found' });
  await auditLog({ actorUserId: req.user.id, action: 'product.update', targetType: 'product', targetId: req.params.id, ip: req.ip });
  return res.json({ ok: true });
});

router.delete('/products/:id', async (req, res) => {
  await deleteImagesForOwners('product', [req.params.id]);
  await query(`DELETE FROM products WHERE id = ?`, [req.params.id]);
  await auditLog({ actorUserId: req.user.id, action: 'product.delete', targetType: 'product', targetId: req.params.id, ip: req.ip });
  return res.json({ ok: true });
});

router.post('/products/:id/images', rawImage, async (req, res) => {
  const result = await storeImage('product', req.params.id, req.body, req.user.id);
  return res.status(result.status).json(result.body);
});

router.delete('/products/images/:imageId', async (req, res) => {
  await deleteImage('product', req.params.imageId);
  return res.json({ ok: true });
});

router.post('/live', async (req, res) => {
  const schema = z.object({
    title: z.string().min(1),
    streamUrl: z.string().url(),
    thumbnailUrl: z.string().url().optional(),
    startsAt: z.string(),
    endsAt: z.string().optional(),
  });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'Invalid input' });
  const id = uuidv4();
  await query(`UPDATE live_sessions SET is_active = 0 WHERE is_active = 1`);
  await query(
    `INSERT INTO live_sessions (id, title, stream_url, thumbnail_url, starts_at, ends_at, is_active)
     VALUES (?, ?, ?, ?, ?, ?, 1)`,
    [
      id,
      parsed.data.title,
      parsed.data.streamUrl,
      parsed.data.thumbnailUrl ?? null,
      parsed.data.startsAt,
      parsed.data.endsAt ?? null,
    ]
  );
  return res.status(201).json({ id });
});

router.get('/guide', async (_req, res) => {
  return res.json(await guideForCrew());
});

router.post('/guide/upload-session', async (_req, res) => {
  const upload = beginGuideUpload();
  if (!upload) return res.status(503).json({ error: 'Storage not configured' });
  return res.json({ upload });
});

router.post('/guide/confirm', async (req, res) => {
  try {
    return res.json(await confirmGuideUpload(String(req.body?.key || '')));
  } catch (err) {
    return res.status(err.status || 500).json({ error: err.message || 'Confirm failed' });
  }
});

export default router;
