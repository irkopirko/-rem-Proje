import { Router } from 'express';
import { imageUrl, readImage } from '../services/contentImages.js';
import { profilePhotoUrl, readProfilePhoto } from '../services/profilePhotos.js';
import { homeworkSubmissionUrl, readHomeworkSubmission } from '../services/homeworkSubmissions.js';
import { feedMediaPublicUrl, feedThumbnailPublicUrl, readFeedMedia, readFeedThumbnail } from '../services/feed.js';
import { readProgramCover } from '../services/programs.js';
import { signedVideoThumbUrl } from '../services/videoCatalog.js';

const router = Router();

const UUID = /^[0-9a-f-]{36}$/i;

// Public on purpose: native image views cannot attach auth headers. Ids are random UUIDs and only
// crew-authored images plus profile photos (visible to the community anyway) live here.
function send(res, image, cdnUrl) {
  if (image.storageKey && cdnUrl.startsWith('https://')) return res.redirect(302, cdnUrl);
  if (!image.data) return res.status(404).end();
  res.set({
    'Content-Type': image.mimeType,
    'Cache-Control': 'public, max-age=604800, immutable',
    'X-Content-Type-Options': 'nosniff',
    'Cross-Origin-Resource-Policy': 'cross-origin',
  });
  return res.send(image.data);
}

function serve(kind) {
  return async (req, res) => {
    if (!UUID.test(req.params.id)) return res.status(404).end();
    const image = await readImage(kind, req.params.id);
    if (!image) return res.status(404).end();
    return send(res, image, imageUrl(kind, req.params.id, image.storageKey));
  };
}

router.get('/product-images/:id', serve('product'));
router.get('/homework-images/:id', serve('homework'));

router.get('/profile-photos/:id', async (req, res) => {
  if (!UUID.test(req.params.id)) return res.status(404).end();
  const photo = await readProfilePhoto(req.params.id);
  if (!photo) return res.status(404).end();
  return send(res, photo, profilePhotoUrl(req.params.id, photo.storageKey));
});

router.get('/feed-media/:id', async (req, res) => {
  if (!UUID.test(req.params.id)) return res.status(404).end();
  const file = await readFeedMedia(req.params.id);
  if (!file) return res.status(404).end();
  return send(res, file, feedMediaPublicUrl(req.params.id, file.storageKey));
});

router.get('/feed-thumbnails/:id', async (req, res) => {
  if (!UUID.test(req.params.id)) return res.status(404).end();
  const file = await readFeedThumbnail(req.params.id);
  if (!file) return res.status(404).end();
  return send(res, file, feedThumbnailPublicUrl(req.params.id, file.storageKey));
});

router.get('/program-covers/:id', async (req, res) => {
  if (!UUID.test(req.params.id)) return res.status(404).end();
  const cover = await readProgramCover(req.params.id);
  if (!cover?.url) return res.status(404).end();
  if (/^https?:\/\//i.test(cover.url)) return res.redirect(302, cover.url);
  return res.status(404).end();
});

router.get('/video-thumbs/:id', async (req, res) => {
  if (!UUID.test(req.params.id)) return res.status(404).end();
  const url = await signedVideoThumbUrl(req.params.id);
  if (!url || !url.startsWith('https://')) return res.status(404).end();
  res.set({
    'Cache-Control': 'public, max-age=3600',
    'Cross-Origin-Resource-Policy': 'cross-origin',
  });
  return res.redirect(302, url);
});

router.get('/homework-submissions/:id', async (req, res) => {
  if (!UUID.test(req.params.id)) return res.status(404).end();
  const file = await readHomeworkSubmission(req.params.id);
  if (!file) return res.status(404).end();
  return send(res, file, homeworkSubmissionUrl(req.params.id, file.storageKey));
});

export default router;
