import { query } from '../db.js';
import { getStreamVideo, isStreamConfigured, mapStreamStatus, streamThumbnailUrl } from './bunny.js';

/** Public shape shared by crew and student endpoints. */
export function videoDTO(row, progress) {
  return {
    id: row.id,
    moduleId: row.module_id,
    videoNumber: Number(row.video_number),
    title: row.title,
    description: row.description,
    durationSeconds: row.duration_seconds ?? 0,
    status: row.status,
    isPublished: Boolean(row.is_published),
    allowTrial: Boolean(row.allow_trial),
    width: row.width,
    height: row.height,
    thumbnailUrl: row.bunny_video_id && row.status === 'ready' ? `/media/video-thumbs/${row.id}` : null,
    ...(progress !== undefined
      ? {
          completed: Boolean(progress?.completed),
          lastPositionSeconds: progress?.last_position_seconds ?? 0,
        }
      : {}),
  };
}

/** Pulls the latest encoding state from Bunny and stores it. Returns the updated row. */
export async function syncVideoFromBunny(row) {
  if (!row.bunny_video_id || !isStreamConfigured()) return row;
  const remote = await getStreamVideo(row.bunny_video_id);
  if (!remote) {
    await query(`UPDATE videos SET status = 'failed' WHERE id = ?`, [row.id]);
    return { ...row, status: 'failed' };
  }
  const status = row.status === 'awaiting_upload' && remote.status === 0 ? 'awaiting_upload' : mapStreamStatus(remote.status);
  const duration = Math.round(remote.length || 0);
  await query(
    `UPDATE videos SET status = ?, duration_seconds = ?, width = ?, height = ? WHERE id = ?`,
    [status, duration, remote.width || null, remote.height || null, row.id]
  );
  return { ...row, status, duration_seconds: duration, width: remote.width || null, height: remote.height || null };
}

/** Webhooks can be missed; re-check any video that is not yet ready. */
export async function refreshStaleProcessing(rows, limit = 15) {
  const stale = rows
    .filter((r) => r.bunny_video_id && r.status !== 'ready' && r.status !== 'failed')
    .slice(0, limit);
  if (!stale.length) return rows;
  const updated = await Promise.all(stale.map((r) => syncVideoFromBunny(r).catch(() => r)));
  const byId = Object.fromEntries(updated.map((r) => [r.id, r]));
  return rows.map((r) => byId[r.id] ?? r);
}

export async function signedVideoThumbUrl(videoId) {
  const [row] = await query(`SELECT bunny_video_id AS guid, status FROM videos WHERE id = ? LIMIT 1`, [videoId]);
  if (!row?.guid || row.status !== 'ready') return null;
  return streamThumbnailUrl(row.guid);
}

export async function ensurePlayable(row) {
  if (!row) return row;
  if (row.status === 'ready' && row.bunny_video_id) return row;
  if (!row.bunny_video_id) return row;
  return syncVideoFromBunny(row).catch(() => row);
}
