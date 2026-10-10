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
    thumbnailUrl: row.bunny_video_id && row.status === 'ready' ? streamThumbnailUrl(row.bunny_video_id) : null,
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

/** Webhooks can be missed; lazily re-check videos stuck in processing for more than a minute. */
export async function refreshStaleProcessing(rows, limit = 10) {
  const stale = rows
    .filter((r) => r.status === 'processing' && Date.now() - new Date(r.updated_at).getTime() > 60_000)
    .slice(0, limit);
  if (!stale.length) return rows;
  const updated = await Promise.all(stale.map((r) => syncVideoFromBunny(r).catch(() => r)));
  const byId = Object.fromEntries(updated.map((r) => [r.id, r]));
  return rows.map((r) => byId[r.id] ?? r);
}
