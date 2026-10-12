import express, { Router } from 'express';
import { z } from 'zod';
import { requireAuth } from '../middleware/auth.js';
import {
  MAX_FEED_VIDEO_BYTES,
  addPostMedia,
  addReplyMedia,
  canUseFeed,
  canWriteFeed,
  createPost,
  createReply,
  deletePost,
  deleteReply,
  getPostForViewer,
  latestPost,
  listPosts,
  listReplies,
  publicAuthor,
  reportPost,
  reportReply,
  toggleLike,
} from '../services/feed.js';

const router = Router();
router.use(requireAuth);
router.use((req, res, next) => {
  if (!canUseFeed(req.user)) return res.status(402).json({ error: 'Membership required' });
  next();
});

const rawMedia = express.raw({ type: () => true, limit: MAX_FEED_VIDEO_BYTES });

router.get('/posts', async (req, res) => {
  const result = await listPosts(req.user, { cursor: req.query.cursor, limit: req.query.limit });
  return res.json(result);
});

router.get('/latest', async (req, res) => {
  return res.json({ post: await latestPost(req.user) });
});

router.get('/posts/:id', async (req, res) => {
  const post = await getPostForViewer(req.user, req.params.id);
  if (!post) return res.status(404).json({ error: 'Not found' });
  return res.json({ post });
});

router.post('/posts', async (req, res) => {
  if (!canWriteFeed(req.user)) return res.status(402).json({ error: 'Membership required' });
  const parsed = z
    .object({
      body: z.string().max(2000).optional(),
      clientRequestId: z.string().uuid().optional(),
    })
    .safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'Invalid input' });
  const result = await createPost(req.user, parsed.data);
  return res.status(result.status).json(result.body);
});

router.post('/posts/:id/media', rawMedia, async (req, res) => {
  if (!Buffer.isBuffer(req.body) || !req.body.length) return res.status(400).json({ error: 'Invalid file' });
  const result = await addPostMedia(req.user, req.params.id, req.body);
  return res.status(result.status).json(result.body);
});

router.delete('/posts/:id', async (req, res) => {
  const result = await deletePost(req.user, req.params.id);
  return res.status(result.status).json(result.body);
});

router.post('/posts/:id/like', async (req, res) => {
  const result = await toggleLike(req.user, req.params.id);
  return res.status(result.status).json(result.body);
});

router.get('/posts/:id/replies', async (req, res) => {
  const post = await getPostForViewer(req.user, req.params.id);
  if (!post) return res.status(404).json({ error: 'Not found' });
  return res.json({ replies: await listReplies(req.user, req.params.id) });
});

router.post('/posts/:id/replies', async (req, res) => {
  const parsed = z
    .object({
      body: z.string().max(500).optional(),
      hasMedia: z.boolean().optional(),
      parentReplyId: z.string().uuid().optional(),
      clientRequestId: z.string().uuid().optional(),
    })
    .safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'Invalid input' });
  const result = await createReply(req.user, req.params.id, parsed.data);
  return res.status(result.status).json(result.body);
});

router.post('/replies/:id/media', rawMedia, async (req, res) => {
  if (!Buffer.isBuffer(req.body) || !req.body.length) return res.status(400).json({ error: 'Invalid file' });
  const result = await addReplyMedia(req.user, req.params.id, req.body);
  return res.status(result.status).json(result.body);
});

router.delete('/replies/:id', async (req, res) => {
  const result = await deleteReply(req.user, req.params.id);
  return res.status(result.status).json(result.body);
});

router.post('/posts/:id/report', async (req, res) => {
  const parsed = z.object({ reason: z.string().max(500).optional() }).safeParse(req.body ?? {});
  const result = await reportPost(req.user, req.params.id, parsed.success ? parsed.data.reason : undefined);
  return res.status(result.status).json(result.body);
});

router.post('/replies/:id/report', async (req, res) => {
  const parsed = z.object({ reason: z.string().max(500).optional() }).safeParse(req.body ?? {});
  const result = await reportReply(req.user, req.params.id, parsed.success ? parsed.data.reason : undefined);
  return res.status(result.status).json(result.body);
});

router.get('/authors/:userId', async (req, res) => {
  const author = await publicAuthor(req.params.userId);
  if (!author) return res.status(404).json({ error: 'Not found' });
  return res.json({ author });
});

export default router;
