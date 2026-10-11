import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { getPool } from './db.js';
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
