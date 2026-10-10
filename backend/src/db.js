import mysql from 'mysql2/promise';

let pool;

export function getPool() {
  if (!pool) {
    const url = process.env.DATABASE_URL;
    if (!url) {
      throw new Error('DATABASE_URL is required');
    }
    pool = mysql.createPool({
      uri: url,
      connectionLimit: Number(process.env.DB_POOL_SIZE || 20),
      maxIdle: 5,
      idleTimeout: 60_000,
      enableKeepAlive: true,
      keepAliveInitialDelay: 10_000,
      timezone: 'Z',
      charset: 'utf8mb4_unicode_ci',
    });
  }
  return pool;
}

export async function query(sql, params = []) {
  const [rows] = await getPool().execute(sql, params);
  return rows;
}
