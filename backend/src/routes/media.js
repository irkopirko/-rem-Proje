import { Router } from 'express';
import { imageUrl, readImage } from '../services/contentImages.js';
import { profilePhotoUrl, readProfilePhoto } from '../services/profilePhotos.js';

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

export default router;
