const PAID = new Set(['plus', 'light', 'life_plus']);
const BLOCKED = new Set(['trial_expired', 'none']);

export function isStaff(user) {
  return user?.role === 'crew' || user?.role === 'super_admin';
}

export function isPaidMember(user) {
  return isStaff(user) || PAID.has(user?.membership_status);
}

export function canSeeHomework(user) {
  return isPaidMember(user);
}

export function isBlockedMembership(user) {
  return !isStaff(user) && BLOCKED.has(user?.membership_status);
}

/** Trial students only see videos crew marked allow_trial. Paid and staff see every published video. */
export function canWatchVideo(user, video) {
  if (isStaff(user)) return true;
  if (isBlockedMembership(user)) return false;
  if (PAID.has(user?.membership_status)) return true;
  if (user?.membership_status === 'trial') return Boolean(video?.allow_trial);
  return false;
}

/** Extra SQL AND-clause so catalogue counts match what the student can open. */
export function studentVideoAccessSql(user, alias = 'v') {
  if (isStaff(user) || PAID.has(user?.membership_status)) return '1=1';
  if (user?.membership_status === 'trial') return `${alias}.allow_trial = 1`;
  return '0=1';
}

const PURPLE_USERNAMES = new Set(['inkakademicrew', 'vuralemekci', 'iremcelik']);

export function avatarFrame(user) {
  const username = String(user?.username || '').toLowerCase();
  if (user?.role === 'crew' || PURPLE_USERNAMES.has(username)) return 'purple';
  return isPaidMember(user) ? 'gold' : 'gray';
}
