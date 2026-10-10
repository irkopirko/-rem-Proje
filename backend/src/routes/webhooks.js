import crypto from 'crypto';
import { Router } from 'express';
import { query } from '../db.js';
import { syncVideoFromBunny } from '../services/videoCatalog.js';

const router = Router();

function secretMatches(provided) {
  const expected = process.env.BUNNY_WEBHOOK_SECRET;
  if (!expected || typeof provided !== 'string') return false;
  const a = Buffer.from(provided);
  const b = Buffer.from(expected);
  return a.length === b.length && crypto.timingSafeEqual(a, b);
}

/**
 * Bunny Stream encoding updates. The body is only used to know *which* video changed;
 * the actual state is always re-read from the Bunny API.
 */
router.post('/bunny-stream', async (req, res) => {
  if (!secretMatches(req.query.secret)) return res.status(401).end();
  const guid = String(req.body?.VideoGuid || '');
  if (!/^[0-9a-f-]{36}$/i.test(guid)) return res.status(200).json({ ignored: true });
  const [row] = await query(`SELECT * FROM videos WHERE bunny_video_id = ? LIMIT 1`, [guid]);
  if (row) await syncVideoFromBunny(row);
  return res.json({ ok: true });
});

export default router;
