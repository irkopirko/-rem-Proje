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

/** MySQL TINYINT comes back as 0/1, not true/false. */
export function audienceFlag(value) {
  return value === true || value === 1 || value === '1';
}

function homeworkAllowTrial(homework) {
  return audienceFlag(homework?.allow_trial) || audienceFlag(homework?.allowTrial);
}

function homeworkAllowPaid(homework) {
  if (homework?.allow_paid === undefined && homework?.allowPaid === undefined) return true;
  return audienceFlag(homework?.allow_paid) || audienceFlag(homework?.allowPaid);
}

/** Per-homework audience: trial and paid packages are independent, like video allow_trial. */
export function canSeeHomeworkItem(user, homework) {
  if (isStaff(user)) return true;
  if (isBlockedMembership(user)) return false;
  if (PAID.has(user?.membership_status)) return homeworkAllowPaid(homework);
  if (user?.membership_status === 'trial') return homeworkAllowTrial(homework);
  return false;
}

export function studentHomeworkAccessSql(user, alias = 'h') {
  if (isStaff(user)) return '1=1';
  if (PAID.has(user?.membership_status)) return `${alias}.allow_paid = 1`;
  if (user?.membership_status === 'trial') return `${alias}.allow_trial = 1`;
  return '0=1';
}

export function isBlockedMembership(user) {
  return !isStaff(user) && BLOCKED.has(user?.membership_status);
}

/** Trial students only watch videos crew marked allow_trial. Paid and staff see every published video. */
export function canWatchVideo(user, video) {
  if (isStaff(user)) return true;
  if (isBlockedMembership(user)) return false;
  if (PAID.has(user?.membership_status)) return true;
  if (user?.membership_status === 'trial') {
    return audienceFlag(video?.allow_trial) || audienceFlag(video?.allowTrial);
  }
  return false;
}

/** Extra SQL AND-clause so catalogue counts match what the student can open. */
export function studentVideoAccessSql(user, alias = 'v') {
  if (isStaff(user) || PAID.has(user?.membership_status)) return '1=1';
  if (user?.membership_status === 'trial') return `${alias}.allow_trial = 1`;
  return '0=1';
}

/** Liste: deneme kullanıcısı üyelik-only içerikleri de görür (kilitli). Oynatma hâlâ canWatchVideo. */
export function studentVideoCatalogSql(user, alias = 'v') {
  if (isStaff(user) || PAID.has(user?.membership_status) || user?.membership_status === 'trial' || user?.membership_status === 'trial_expired') {
    return '1=1';
  }
  return '0=1';
}

/** Liste: deneme kullanıcısı üyelik-only ödevleri de görür (kilitli). Teslim hâlâ canSeeHomeworkItem. */
export function studentHomeworkCatalogSql(user, alias = 'h') {
  if (isStaff(user) || PAID.has(user?.membership_status) || user?.membership_status === 'trial' || user?.membership_status === 'trial_expired') {
    return '1=1';
  }
  return '0=1';
}

const PURPLE_USERNAMES = new Set(['inkakademicrew', 'vuralemekci', 'iremcelik']);

export function avatarFrame(user) {
  const username = String(user?.username || '').toLowerCase();
  if (user?.role === 'crew' || PURPLE_USERNAMES.has(username)) return 'purple';
  return isPaidMember(user) ? 'gold' : 'gray';
}
