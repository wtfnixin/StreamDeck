import Database from 'better-sqlite3';
import path from 'path';
import { env } from '../config/env';
import { logger } from '../logger/winston';
import fs from 'fs';

const dbDir = path.dirname(path.resolve(env.DATABASE_PATH));
if (!fs.existsSync(dbDir)) {
  fs.mkdirSync(dbDir, { recursive: true });
}

let db: Database.Database;

try {
  db = new Database(env.DATABASE_PATH, { verbose: (message) => logger.debug(`[DB] ${message}`) });
  db.pragma('journal_mode = WAL');
  logger.info(`💾 Database connected successfully at ${env.DATABASE_PATH}`);
} catch (error) {
  logger.error('❌ Failed to connect to SQLite database:', error);
  process.exit(1);
}

export { db };
