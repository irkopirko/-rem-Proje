import { verifyAccessToken } from '../utils/jwt.js';
import { query } from '../db.js';

export async function requireAuth(req, res, next) {
  try {
    const header = req.headers.authorization || '';
    const token = header.startsWith('Bearer ') ? header.slice(7) : null;
    if (!token) {
      return res.status(401).json({ error: 'Unauthorized' });
    }
    const payload = verifyAccessToken(token);
    const rows = await query(
      `SELECT id, email, role, first_name, last_name, membership_status, chat_banned, deleted_at
       FROM users WHERE id = ? LIMIT 1`,
      [payload.sub]
    );
    const user = rows[0];
    if (!user || user.deleted_at) {
      return res.status(401).json({ error: 'Unauthorized' });
    }
    req.user = user;
    next();
  } catch {
    return res.status(401).json({ error: 'Unauthorized' });
  }
}

export function requireRole(...roles) {
  return (req, res, next) => {
    if (!req.user || !roles.includes(req.user.role)) {
      return res.status(403).json({ error: 'Forbidden' });
    }
    next();
  };
}

export const requireStudent = requireRole('student');
export const requireCrew = requireRole('crew', 'super_admin');
export const requireSuperAdmin = requireRole('super_admin');
