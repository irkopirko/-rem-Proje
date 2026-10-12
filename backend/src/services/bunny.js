import crypto from 'crypto';

/**
 * Bunny Stream (videos: HLS adaptive streaming, original quality kept as top rendition)
 * and Bunny Storage + CDN (images). All keys come from env vars only.
 */
function env(name) {
  const value = process.env[name];
  return value && value.trim() ? value.trim() : null;
}

const stream = () => ({
  libraryId: env('BUNNY_STREAM_LIBRARY_ID'),
  apiKey: env('BUNNY_STREAM_API_KEY'),
  cdnHost: env('BUNNY_STREAM_CDN_HOST'), // e.g. vz-abc123-456.b-cdn.net
  tokenKey: env('BUNNY_STREAM_TOKEN_KEY'), // Stream → Security → CDN token authentication key
});

const storage = () => ({
  zone: env('BUNNY_STORAGE_ZONE'),
  apiKey: env('BUNNY_STORAGE_API_KEY'), // storage zone password
  host: env('BUNNY_STORAGE_HOST') || 'storage.bunnycdn.com',
  cdnHost: env('BUNNY_CDN_HOST'), // pull zone hostname, e.g. inkakademi.b-cdn.net
  tokenKey: env('BUNNY_CDN_TOKEN_KEY'),
});

export const isStreamConfigured = () => {
  const s = stream();
  return Boolean(s.libraryId && s.apiKey && s.cdnHost);
};

export const isStorageConfigured = () => {
  const s = storage();
  return Boolean(s.zone && s.apiKey && s.cdnHost);
};

export class BunnyError extends Error {
  constructor(message, status) {
    super(message);
    this.status = status;
  }
}

async function streamApi(path, { method = 'GET', body } = {}) {
  const s = stream();
  const res = await fetch(`https://video.bunnycdn.com/library/${s.libraryId}${path}`, {
    method,
    headers: {
      AccessKey: s.apiKey,
      Accept: 'application/json',
      ...(body ? { 'Content-Type': 'application/json' } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  if (res.status === 404) return null;
  if (!res.ok) throw new BunnyError(`Bunny Stream ${method} ${path} failed (${res.status})`, res.status);
  const text = await res.text();
  return text ? JSON.parse(text) : {};
}

export async function createStreamVideo(title) {
  const video = await streamApi('/videos', { method: 'POST', body: { title } });
  return video.guid;
}

export async function getStreamVideo(guid) {
  return streamApi(`/videos/${guid}`);
}

export async function deleteStreamVideo(guid) {
  if (!guid || !isStreamConfigured()) return;
  try {
    await streamApi(`/videos/${guid}`, { method: 'DELETE' });
  } catch (err) {
    console.error('[bunny] delete video failed', guid, err.message);
  }
}

/** Bunny status codes → our status. 4 = finished; 5/6 = failed. */
export function mapStreamStatus(code) {
  if (code === 4) return 'ready';
  if (code === 5 || code === 6) return 'failed';
  if (code === 0) return 'awaiting_upload';
  return 'processing';
}

/** Credentials for a resumable TUS upload straight from the device to Bunny (never via our server). */
export function tusCredentials(guid, ttlSeconds = 24 * 3600) {
  const s = stream();
  const expire = Math.floor(Date.now() / 1000) + ttlSeconds;
  const signature = crypto
    .createHash('sha256')
    .update(`${s.libraryId}${s.apiKey}${expire}${guid}`)
    .digest('hex');
  return {
    endpoint: 'https://video.bunnycdn.com/tusupload',
    libraryId: s.libraryId,
    videoId: guid,
    expire,
    signature,
  };
}

function normalizeCdnHost(host) {
  return String(host || '')
    .trim()
    .replace(/^https?:\/\//i, '')
    .replace(/\/+$/, '')
    .split('/')[0];
}

/**
 * Bunny advanced token authentication (HMAC-SHA256, HS256- prefix).
 * With `directory`, the token sits in the path so HLS segments inherit it.
 * @see https://github.com/BunnyWay/BunnyCDN.TokenAuthentication
 */
export function signBunnyUrl({ host, path, tokenKey, expires, directory }) {
  const cleanHost = normalizeCdnHost(host);
  const cleanPath = path.startsWith('/') ? path : `/${path}`;
  if (!cleanHost) return cleanPath;
  if (!tokenKey) return `https://${cleanHost}${cleanPath}`;

  const expiresStr = String(expires);
  const parameters = directory ? { token_path: directory } : {};
  const sortedEntries = Object.entries(parameters).sort(([a], [b]) => a.localeCompare(b));
  const signaturePath = directory || cleanPath;
  const signingData = sortedEntries.map(([k, v]) => `${k}=${v}`).join('&');
  const urlData = sortedEntries.map(([k, v]) => `${k}=${encodeURIComponent(v)}`).join('&');

  const hmac = crypto.createHmac('sha256', tokenKey);
  hmac.update(signaturePath);
  hmac.update(expiresStr);
  hmac.update(signingData);
  const token =
    'HS256-' +
    hmac.digest('base64').replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');

  const tail = urlData ? `&${urlData}` : '';
  if (directory) {
    return `https://${cleanHost}/bcdn_token=${token}${tail}&expires=${expiresStr}${cleanPath}`;
  }
  return `https://${cleanHost}${cleanPath}?token=${token}${tail}&expires=${expiresStr}`;
}

/** Expiry that stays constant for a whole UTC day, so signed thumbnail URLs remain cacheable. */
export function stableDailyExpiry(extraDays = 1) {
  const now = new Date();
  const endOfDay = Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() + 1 + extraDays);
  return Math.floor(endOfDay / 1000);
}

export function streamPlaybackUrl(guid, ttlSeconds = 6 * 3600) {
  const s = stream();
  const expires = Math.floor(Date.now() / 1000) + ttlSeconds;
  const id = String(guid).trim();
  return {
    url: signBunnyUrl({
      host: s.cdnHost,
      path: `/${id}/playlist.m3u8`,
      tokenKey: s.tokenKey,
      expires,
      directory: `/${id}/`,
    }),
    expiresAt: new Date(expires * 1000).toISOString(),
  };
}

/** Bunny player iframe. Direct HLS is blocked when the library forbids raw file access. */
export function streamEmbedUrl(guid, ttlSeconds = 6 * 3600) {
  const s = stream();
  const id = String(guid).trim();
  const expires = Math.floor(Date.now() / 1000) + ttlSeconds;
  const params = new URLSearchParams({
    autoplay: 'true',
    preload: 'true',
    responsive: 'true',
  });
  if (s.tokenKey) {
    const token = crypto.createHash('sha256').update(`${s.tokenKey}${id}${expires}`).digest('hex');
    params.set('token', token);
    params.set('expires', String(expires));
  }
  return {
    url: `https://iframe.mediadelivery.net/embed/${s.libraryId}/${id}?${params}`,
    expiresAt: new Date(expires * 1000).toISOString(),
  };
}

export function streamThumbnailUrl(guid) {
  const s = stream();
  if (!s.cdnHost || !guid) return null;
  const id = String(guid).trim();
  return signBunnyUrl({
    host: s.cdnHost,
    path: `/${id}/thumbnail.jpg`,
    tokenKey: s.tokenKey,
    expires: stableDailyExpiry(),
    directory: `/${id}/`,
  });
}

export async function uploadToStorage(key, buffer, contentType) {
  const s = storage();
  const res = await fetch(`https://${s.host}/${s.zone}/${key}`, {
    method: 'PUT',
    headers: { AccessKey: s.apiKey, 'Content-Type': contentType || 'application/octet-stream' },
    body: buffer,
  });
  if (!res.ok) throw new BunnyError(`Bunny Storage upload failed (${res.status})`, res.status);
}

export async function downloadFromStorage(key) {
  if (!key || !isStorageConfigured()) return null;
  const s = storage();
  const res = await fetch(`https://${s.host}/${s.zone}/${key}`, { headers: { AccessKey: s.apiKey } });
  if (!res.ok) return null;
  return {
    data: Buffer.from(await res.arrayBuffer()),
    mimeType: res.headers.get('content-type') || 'application/octet-stream',
  };
}

export async function deleteFromStorage(key) {
  if (!key || !isStorageConfigured()) return;
  const s = storage();
  try {
    await fetch(`https://${s.host}/${s.zone}/${key}`, { method: 'DELETE', headers: { AccessKey: s.apiKey } });
  } catch (err) {
    console.error('[bunny] storage delete failed', key, err.message);
  }
}

export function storageCdnUrl(key) {
  const s = storage();
  if (!s.cdnHost) return null;
  return signBunnyUrl({ host: s.cdnHost, path: `/${key}`, tokenKey: s.tokenKey, expires: stableDailyExpiry() });
}

/** Authenticated crew uploads the file itself (book-sized PDFs must not pass through Railway). */
export function storagePutTarget(key, contentType) {
  const s = storage();
  if (!isStorageConfigured()) return null;
  return {
    url: `https://${s.host}/${s.zone}/${key}`,
    method: 'PUT',
    headers: { AccessKey: s.apiKey, 'Content-Type': contentType || 'application/octet-stream' },
    key,
  };
}
