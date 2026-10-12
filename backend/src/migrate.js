import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { getPool } from './db.js';
import { ensureAcademyProgram } from './services/programs.js';
import 'dotenv/config';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

async function addColumnIfMissing(pool, table, column, definition) {
  const [rows] = await pool.query(
    `SELECT 1 FROM information_schema.COLUMNS
     WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND COLUMN_NAME = ?`,
    [table, column]
  );
  if (!rows.length) {
    await pool.query(`ALTER TABLE ${table} ADD COLUMN ${column} ${definition}`);
  }
}

async function makeNullable(pool, table, column, definition) {
  const [rows] = await pool.query(
    `SELECT IS_NULLABLE AS nullable FROM information_schema.COLUMNS
     WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND COLUMN_NAME = ?`,
    [table, column]
  );
  if (rows.length && rows[0].nullable === 'NO') {
    await pool.query(`ALTER TABLE ${table} MODIFY ${column} ${definition} NULL`);
  }
}

async function addIndexIfMissing(pool, table, index, columns) {
  const [rows] = await pool.query(
    `SELECT 1 FROM information_schema.STATISTICS
     WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND INDEX_NAME = ?`,
    [table, index]
  );
  if (!rows.length) await pool.query(`CREATE INDEX ${index} ON ${table} (${columns})`);
}

/** Idempotent: safe to run on every boot. */
export async function runMigrations() {
  const sql = fs.readFileSync(path.join(__dirname, '../sql/001_schema.sql'), 'utf8');
  const statements = sql
    .split(';')
    .map((s) => s.trim())
    .filter(Boolean);

  const pool = getPool();
  for (const statement of statements) {
    await pool.query(statement);
  }

  await addColumnIfMissing(pool, 'users', 'username', 'VARCHAR(20) NULL UNIQUE AFTER user_no');
  await addColumnIfMissing(pool, 'homework', 'assign_to_all', 'TINYINT(1) NOT NULL DEFAULT 1 AFTER due_at');
  await addColumnIfMissing(pool, 'users', 'xp', 'INT UNSIGNED NOT NULL DEFAULT 0 AFTER membership_expires_at');
  await addColumnIfMissing(pool, 'badges', 'xp_reward', 'INT UNSIGNED NOT NULL DEFAULT 0 AFTER description');
  await addColumnIfMissing(pool, 'homework_submissions', 'data', 'MEDIUMBLOB NULL AFTER file_mime');
  await addColumnIfMissing(pool, 'homework_submissions', 'storage_key', 'VARCHAR(255) NULL AFTER data');
  await addColumnIfMissing(pool, 'homework_submissions', 'file_size', 'BIGINT UNSIGNED NULL AFTER storage_key');
  await addColumnIfMissing(pool, 'homework_submissions', 'file_name', 'VARCHAR(180) NULL AFTER file_size');

  for (const table of ['product_images', 'homework_images']) {
    await makeNullable(pool, table, 'data', 'MEDIUMBLOB');
    await addColumnIfMissing(pool, table, 'storage_key', 'VARCHAR(255) NULL AFTER data');
  }

  await makeNullable(pool, 'videos', 'stream_url', 'TEXT');
  await addColumnIfMissing(pool, 'videos', 'bunny_video_id', 'VARCHAR(64) NULL UNIQUE AFTER thumbnail_url');
  await addColumnIfMissing(
    pool,
    'videos',
    'status',
    "ENUM('awaiting_upload','processing','ready','failed') NOT NULL DEFAULT 'awaiting_upload' AFTER bunny_video_id"
  );
  await addColumnIfMissing(pool, 'videos', 'width', 'INT UNSIGNED NULL AFTER status');
  await addColumnIfMissing(pool, 'videos', 'height', 'INT UNSIGNED NULL AFTER width');
  await addColumnIfMissing(pool, 'videos', 'uploaded_by_user_id', 'CHAR(36) NULL AFTER height');
  await addColumnIfMissing(pool, 'videos', 'allow_trial', 'TINYINT(1) NOT NULL DEFAULT 0 AFTER is_published');
  await addColumnIfMissing(pool, 'homework', 'allow_trial', 'TINYINT(1) NOT NULL DEFAULT 0 AFTER assign_to_all');
  await addColumnIfMissing(pool, 'homework', 'allow_paid', 'TINYINT(1) NOT NULL DEFAULT 1 AFTER allow_trial');
  await addIndexIfMissing(pool, 'videos', 'idx_videos_module_order', 'module_id, sort_order');
  await addIndexIfMissing(pool, 'videos', 'idx_videos_status', 'status');

  const feedTables = [
    `CREATE TABLE IF NOT EXISTS feed_posts (
      id CHAR(36) PRIMARY KEY,
      user_id CHAR(36) NOT NULL,
      body TEXT NOT NULL,
      client_request_id CHAR(36) NULL,
      created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
      updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      deleted_at DATETIME NULL,
      deleted_by_user_id CHAR(36) NULL,
      FOREIGN KEY (user_id) REFERENCES users(id),
      UNIQUE KEY uq_feed_post_client (user_id, client_request_id),
      INDEX idx_feed_posts_created (deleted_at, created_at, id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci`,
    `CREATE TABLE IF NOT EXISTS feed_media (
      id CHAR(36) PRIMARY KEY,
      post_id CHAR(36) NOT NULL,
      kind ENUM('image','video') NOT NULL,
      mime_type VARCHAR(80) NOT NULL,
      byte_size INT UNSIGNED NOT NULL,
      storage_key VARCHAR(255) NULL,
      sort_order INT NOT NULL DEFAULT 0,
      uploaded_by_user_id CHAR(36) NULL,
      created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (post_id) REFERENCES feed_posts(id) ON DELETE CASCADE,
      INDEX idx_feed_media_post (post_id, sort_order)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci`,
    `CREATE TABLE IF NOT EXISTS feed_likes (
      user_id CHAR(36) NOT NULL,
      post_id CHAR(36) NOT NULL,
      created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY (user_id, post_id),
      FOREIGN KEY (user_id) REFERENCES users(id),
      FOREIGN KEY (post_id) REFERENCES feed_posts(id) ON DELETE CASCADE,
      INDEX idx_feed_likes_post (post_id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci`,
    `CREATE TABLE IF NOT EXISTS feed_replies (
      id CHAR(36) PRIMARY KEY,
      post_id CHAR(36) NOT NULL,
      parent_reply_id CHAR(36) NULL,
      user_id CHAR(36) NOT NULL,
      body TEXT NOT NULL,
      client_request_id CHAR(36) NULL,
      created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
      deleted_at DATETIME NULL,
      deleted_by_user_id CHAR(36) NULL,
      FOREIGN KEY (post_id) REFERENCES feed_posts(id) ON DELETE CASCADE,
      FOREIGN KEY (user_id) REFERENCES users(id),
      UNIQUE KEY uq_feed_reply_client (user_id, client_request_id),
      INDEX idx_feed_replies_post (post_id, created_at)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci`,
    `CREATE TABLE IF NOT EXISTS feed_reports (
      id CHAR(36) PRIMARY KEY,
      post_id CHAR(36) NULL,
      reply_id CHAR(36) NULL,
      reporter_id CHAR(36) NOT NULL,
      reason VARCHAR(500) NULL,
      created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
      resolved_at DATETIME NULL,
      resolved_by_user_id CHAR(36) NULL,
      UNIQUE KEY uq_feed_report_post (reporter_id, post_id),
      UNIQUE KEY uq_feed_report_reply (reporter_id, reply_id),
      FOREIGN KEY (reporter_id) REFERENCES users(id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci`,
    `CREATE TABLE IF NOT EXISTS xp_reward_events (
      id CHAR(36) PRIMARY KEY,
      user_id CHAR(36) NOT NULL,
      event_key VARCHAR(160) NOT NULL,
      amount INT UNSIGNED NOT NULL,
      created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
      UNIQUE KEY uq_xp_event (user_id, event_key),
      FOREIGN KEY (user_id) REFERENCES users(id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci`,
  ];
  for (const statement of feedTables) {
    await pool.query(statement);
  }
  await addColumnIfMissing(pool, 'feed_media', 'reply_id', 'CHAR(36) NULL AFTER post_id');
  await addColumnIfMissing(pool, 'feed_media', 'data', 'MEDIUMBLOB NULL AFTER storage_key');
  await addIndexIfMissing(pool, 'feed_media', 'idx_feed_media_reply', 'reply_id');

  await pool.query(`CREATE TABLE IF NOT EXISTS education_programs (
      id CHAR(36) PRIMARY KEY,
      slug VARCHAR(80) NULL UNIQUE,
      title VARCHAR(255) NOT NULL,
      description TEXT NULL,
      instructor_name VARCHAR(160) NULL,
      cover_image_url TEXT NULL,
      sort_order INT NOT NULL DEFAULT 0,
      is_published TINYINT(1) NOT NULL DEFAULT 1,
      created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
      updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      INDEX idx_programs_order (is_published, sort_order)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci`);
  await addColumnIfMissing(pool, 'modules', 'education_program_id', 'CHAR(36) NULL AFTER id');
  await addIndexIfMissing(pool, 'modules', 'idx_modules_program', 'education_program_id, sort_order');
  await ensureAcademyProgram();

  console.log('Migration complete.');
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  runMigrations()
    .then(() => process.exit(0))
    .catch((err) => {
      console.error(err);
      process.exit(1);
    });
}
