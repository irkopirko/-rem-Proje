export function rankForLevel(level) {
  if (level >= 20) return 'usta';
  if (level >= 10) return 'kalfa';
  return 'cirak';
}

export function rankLabel(rank) {
  return { cirak: 'Çırak', kalfa: 'Kalfa', usta: 'Usta' }[rank] ?? 'Çırak';
}

/** XP needed to go from (level-1) to level. Level 0 is the start. Level 1 costs 100, then ×1.25 each time. */
export function xpRequiredForLevel(level) {
  if (level <= 0) return 0;
  let need = 100;
  for (let i = 1; i < level; i += 1) need = Math.round(need * 1.25);
  return need;
}

export function levelFromXp(xp) {
  let remaining = Math.max(0, Number(xp) || 0);
  const totalXp = remaining;
  let level = 0;
  while (level < 500) {
    const need = xpRequiredForLevel(level + 1);
    if (remaining < need) {
      return {
        totalXp,
        level,
        rank: rankForLevel(level),
        rankLabel: rankLabel(rankForLevel(level)),
        xpIntoLevel: remaining,
        xpForNextLevel: need,
        xpToNextLevel: need - remaining,
      };
    }
    remaining -= need;
    level += 1;
  }
  return {
    totalXp,
    level,
    rank: rankForLevel(level),
    rankLabel: rankLabel(rankForLevel(level)),
    xpIntoLevel: remaining,
    xpForNextLevel: 0,
    xpToNextLevel: 0,
  };
}
