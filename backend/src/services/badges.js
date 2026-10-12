import { v4 as uuidv4 } from 'uuid';
import { query } from '../db.js';
import { levelFromXp } from './levels.js';

export const BADGE_CATALOG = [
  { slug: 'first-needle', title: 'İlk İğne', description: 'Hesabını onaylayıp Ink Akademi’ye katıl.', xp: 50, sort: 1 },
  { slug: 'face-shown', title: 'Yüzün Görünsün', description: 'Profil fotoğrafı yükle.', xp: 50, sort: 2 },
  { slug: 'hello-studio', title: 'Merhaba Stüdyo', description: 'Topluluk sohbetine ilk mesajını at.', xp: 75, sort: 3 },
  { slug: 'first-lesson', title: 'İlk Ders', description: 'İlk videonu sonuna kadar izle.', xp: 100, sort: 4 },
  { slug: 'apprentice', title: 'Çırak', description: 'Toplam 5 videoyu tamamla.', xp: 100, sort: 5 },
  { slug: 'weekly-hunter', title: 'Haftanın Avcısı', description: 'Gizli nesne oyununu bir kez bitir.', xp: 150, sort: 6 },
  { slug: 'pen-opened', title: 'Kalem Açıldı', description: 'İlk ödevini teslim et.', xp: 150, sort: 7 },
  { slug: 'linework', title: 'Linework', description: 'Bir ödevden 100 alıp geç.', xp: 200, sort: 8 },
  { slug: 'journeyman', title: 'Kalfa', description: 'Toplam 25 videoyu tamamla.', xp: 200, sort: 9 },
  { slug: 'streak-3', title: 'Seri Çalışma', description: '3 gün üst üste en az bir video bitir.', xp: 250, sort: 10 },
  { slug: 'module-closed', title: 'Modül Kapandı', description: 'Bir eğitim modülündeki tüm videoları bitir.', xp: 300, sort: 11 },
  { slug: 'chat-voice', title: 'Sohbetin Sesi', description: 'Toplulukta 25 mesaj at.', xp: 300, sort: 12 },
  { slug: 'revise-master', title: 'Revize Ustası', description: 'Revize istenen bir ödevi düzeltip tekrar geç.', xp: 350, sort: 13 },
  { slug: 'streak-7', title: '7 Gün Stüdyo', description: '7 gün üst üste en az bir video bitir.', xp: 400, sort: 14 },
  { slug: 'homework-book', title: 'Ödev Defteri', description: '5 ödevi başarıyla geç.', xp: 400, sort: 15 },
  { slug: 'master-candidate', title: 'Usta Adayı', description: 'Toplam 75 videoyu tamamla.', xp: 500, sort: 16 },
  { slug: 'three-modules', title: 'Üç Modül', description: '3 farklı modülü tamamen bitir.', xp: 500, sort: 17 },
  { slug: 'game-collection', title: 'Oyun Koleksiyonu', description: 'Oyunu 4 ayrı günde tamamla.', xp: 600, sort: 18 },
  { slug: 'ink-master', title: 'Mürekkep Ustası', description: '15 ödevi başarıyla geç.', xp: 800, sort: 19 },
  { slug: 'academy-graduate', title: 'Akademi Mezunu', description: 'Tüm yayınlanmış modülleri bitir.', xp: 1000, sort: 20 },
];

export async function seedBadges() {
  for (const badge of BADGE_CATALOG) {
    await query(
      `INSERT INTO badges (id, slug, title, description, xp_reward, sort_order)
       VALUES (?, ?, ?, ?, ?, ?)
       ON DUPLICATE KEY UPDATE title = VALUES(title), description = VALUES(description),
         xp_reward = VALUES(xp_reward), sort_order = VALUES(sort_order)`,
      [uuidv4(), badge.slug, badge.title, badge.description, badge.xp, badge.sort]
    );
  }
}

export async function recordVideoDay(userId) {
  await query(
    `INSERT IGNORE INTO user_activity_days (user_id, activity_date) VALUES (?, UTC_DATE())`,
    [userId]
  );
}

function istanbulDate() {
  return new Date().toLocaleDateString('en-CA', { timeZone: 'Europe/Istanbul' });
}

export async function recordWeeklyGameWin(userId) {
  const day = await query(
    `INSERT IGNORE INTO user_game_days (user_id, play_date) VALUES (?, ?)`,
    [userId, istanbulDate()]
  );
  if (day.affectedRows) {
    await query(
      `INSERT IGNORE INTO user_game_weeks (user_id, year_week)
       VALUES (?, YEARWEEK(UTC_TIMESTAMP(), 3))`,
      [userId]
    );
  }
  return Boolean(day.affectedRows);
}

export async function playedGameToday(userId) {
  const [row] = await query(
    `SELECT 1 AS ok FROM user_game_days WHERE user_id = ? AND play_date = ?`,
    [userId, istanbulDate()]
  );
  return Boolean(row);
}

function utcDay(value) {
  if (value instanceof Date) return value.toISOString().slice(0, 10);
  return String(value).slice(0, 10);
}

function consecutiveStreak(dates) {
  if (!dates.length) return 0;
  const newest = utcDay(dates[0]);
  const today = new Date();
  const todayKey = today.toISOString().slice(0, 10);
  const y = new Date(today);
  y.setUTCDate(y.getUTCDate() - 1);
  if (newest !== todayKey && newest !== y.toISOString().slice(0, 10)) return 0;
  const expected = new Date(`${newest}T00:00:00.000Z`);
  let streak = 0;
  for (const value of dates) {
    if (utcDay(value) !== expected.toISOString().slice(0, 10)) break;
    streak += 1;
    expected.setUTCDate(expected.getUTCDate() - 1);
  }
  return streak;
}

async function loadStats(userId) {
  const [row] = await query(
      `SELECT
         (SELECT COUNT(*) FROM video_progress WHERE user_id = ? AND completed = 1) AS videos,
         (SELECT COUNT(*) FROM homework_submissions hs
            JOIN homework_assignments ha ON ha.id = hs.assignment_id
            WHERE ha.student_id = ?) AS submits,
         (SELECT COUNT(*) FROM homework_assignments WHERE student_id = ? AND status = 'graded_pass') AS passed,
         (SELECT COUNT(*) FROM community_messages WHERE user_id = ? AND deleted_at IS NULL) AS messages,
         (SELECT profile_photo_url FROM users WHERE id = ?) AS photo,
         (SELECT COUNT(*) FROM user_game_days WHERE user_id = ?) AS gameWeeks,
         (SELECT COUNT(*) FROM (
            SELECT m.id FROM modules m
            JOIN videos v ON v.module_id = m.id AND v.is_published = 1 AND v.status = 'ready'
            LEFT JOIN video_progress vp ON vp.video_id = v.id AND vp.user_id = ?
            WHERE m.is_published = 1
            GROUP BY m.id
            HAVING COUNT(*) > 0 AND SUM(CASE WHEN vp.completed = 1 THEN 1 ELSE 0 END) = COUNT(*)
          ) done) AS modulesDone,
         (SELECT COUNT(*) FROM modules m
            WHERE m.is_published = 1
              AND EXISTS (SELECT 1 FROM videos v WHERE v.module_id = m.id AND v.is_published = 1 AND v.status = 'ready')
         ) AS modulesTotal,
         (SELECT COUNT(*) FROM homework_assignments ha
            WHERE ha.student_id = ? AND ha.status = 'graded_pass'
              AND EXISTS (SELECT 1 FROM homework_grades hg WHERE hg.assignment_id = ha.id AND hg.is_revision_grade = 1)
         ) AS revisePassed`,
      [userId, userId, userId, userId, userId, userId, userId, userId]
    );
  const days = await query(
    `SELECT activity_date AS day FROM user_activity_days WHERE user_id = ? ORDER BY activity_date DESC LIMIT 21`,
    [userId]
  );
  return { ...row, streak: consecutiveStreak(days.map((d) => new Date(d.day))) };
}

export const XP_PER_VIDEO = 10;
export const XP_PER_HOMEWORK_SUBMIT = 10;
export const XP_FEED_LIKE = 5;
export const XP_FEED_REPLY = 10;

export async function grantXp(userId, amount) {
  const value = Math.max(0, Number(amount) || 0);
  if (!userId || !value) return;
  await query(`UPDATE users SET xp = xp + ? WHERE id = ?`, [value, userId]);
}

/**
 * Idempotent XP: the same (user, eventKey) is awarded at most once.
 * `exec` may be a transaction executor; defaults to the shared pool.
 */
export async function grantXpOnce(userId, eventKey, amount, exec = query) {
  const value = Math.max(0, Number(amount) || 0);
  if (!userId || !eventKey || !value) return { awarded: false, amount: 0 };
  const inserted = await exec(
    `INSERT IGNORE INTO xp_reward_events (id, user_id, event_key, amount) VALUES (?, ?, ?, ?)`,
    [uuidv4(), userId, String(eventKey).slice(0, 160), value]
  );
  if (!inserted.affectedRows) return { awarded: false, amount: 0 };
  await exec(`UPDATE users SET xp = xp + ? WHERE id = ?`, [value, userId]);
  return { awarded: true, amount: value };
}

export async function currentXp(userId) {
  const [row] = await query(`SELECT xp FROM users WHERE id = ? LIMIT 1`, [userId]);
  return Number(row?.xp || 0);
}

async function award(userId, slug) {
  const [badge] = await query(`SELECT id, xp_reward AS xp FROM badges WHERE slug = ? LIMIT 1`, [slug]);
  if (!badge) return false;
  const result = await query(`INSERT IGNORE INTO user_badges (user_id, badge_id) VALUES (?, ?)`, [userId, badge.id]);
  if (!result.affectedRows) return false;
  await grantXp(userId, badge.xp);
  return true;
}

/** Grants every newly qualified badge and deposits its XP once. */
export async function evaluateBadges(userId) {
  if (!userId) return [];
  try {
    const earned = new Set(
      (await query(`SELECT b.slug FROM user_badges ub JOIN badges b ON b.id = ub.badge_id WHERE ub.user_id = ?`, [userId])).map(
        (r) => r.slug
      )
    );
    const stats = await loadStats(userId);
    const qualified = [];
    const mark = (slug, ok) => {
      if (ok && !earned.has(slug)) qualified.push(slug);
    };
    mark('first-needle', true);
    mark('face-shown', Boolean(stats.photo));
    mark('hello-studio', Number(stats.messages) >= 1);
    mark('first-lesson', Number(stats.videos) >= 1);
    mark('apprentice', Number(stats.videos) >= 5);
    mark('weekly-hunter', Number(stats.gameWeeks) >= 1);
    mark('pen-opened', Number(stats.submits) >= 1);
    mark('linework', Number(stats.passed) >= 1);
    mark('journeyman', Number(stats.videos) >= 25);
    mark('streak-3', Number(stats.streak) >= 3);
    mark('module-closed', Number(stats.modulesDone) >= 1);
    mark('chat-voice', Number(stats.messages) >= 25);
    mark('revise-master', Number(stats.revisePassed) >= 1);
    mark('streak-7', Number(stats.streak) >= 7);
    mark('homework-book', Number(stats.passed) >= 5);
    mark('master-candidate', Number(stats.videos) >= 75);
    mark('three-modules', Number(stats.modulesDone) >= 3);
    mark('game-collection', Number(stats.gameWeeks) >= 4);
    mark('ink-master', Number(stats.passed) >= 15);
    mark(
      'academy-graduate',
      Number(stats.modulesTotal) > 0 && Number(stats.modulesDone) >= Number(stats.modulesTotal)
    );

    const unlocked = [];
    for (const slug of qualified) {
      if (await award(userId, slug)) unlocked.push(slug);
    }
    return unlocked;
  } catch (err) {
    console.error('[badges] evaluate failed', err.message);
    return [];
  }
}

export function quietEvaluate(userId) {
  evaluateBadges(userId).catch(() => {});
}

export async function progressFor(userId) {
  const unlocked = await evaluateBadges(userId);
  const [user] = await query(`SELECT xp FROM users WHERE id = ? LIMIT 1`, [userId]);
  const progress = levelFromXp(user?.xp ?? 0);
  const badges = await query(
    `SELECT b.slug, b.title, b.description, b.xp_reward AS xpReward, b.image_url AS imageUrl, b.sort_order AS sortOrder,
            ub.earned_at AS earnedAt
     FROM badges b
     LEFT JOIN user_badges ub ON ub.badge_id = b.id AND ub.user_id = ?
     ORDER BY b.sort_order`,
    [userId]
  );
  const mapped = badges.map((b) => ({
    slug: b.slug,
    title: b.title,
    description: b.description,
    xpReward: Number(b.xpReward),
    imageUrl: b.imageUrl,
    earnedAt: b.earnedAt ? new Date(b.earnedAt).toISOString() : null,
  }));
  return {
    ...progress,
    gamePlayedToday: await playedGameToday(userId),
    newlyEarned: mapped.filter((b) => unlocked.includes(b.slug)),
    badges: mapped,
  };
}
