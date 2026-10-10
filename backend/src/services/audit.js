import { query } from '../db.js';

export async function auditLog({ actorUserId, action, targetType, targetId, metadata, ip }) {
  await query(
    `INSERT INTO audit_logs (actor_user_id, action, target_type, target_id, metadata, ip_address)
     VALUES (?, ?, ?, ?, ?, ?)`,
    [
      actorUserId ?? null,
      action,
      targetType ?? null,
      targetId ?? null,
      metadata ? JSON.stringify(metadata) : null,
      ip ?? null,
    ]
  );
}
