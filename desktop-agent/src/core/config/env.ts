import dotenv from 'dotenv';
import path from 'path';
import fs from 'fs';
import crypto from 'crypto';
import { z } from 'zod';

// Determine the base directory (outside pkg snapshot when packaged)
const isPackaged = typeof (process as any).pkg !== 'undefined';
const baseDir = isPackaged ? path.dirname(process.execPath) : path.join(__dirname, '../../../');
const envPath = path.join(baseDir, '.env');

// If .env doesn't exist, generate a default one with a secure persistent JWT_SECRET
if (!fs.existsSync(envPath)) {
  const defaultSecret = crypto.randomBytes(32).toString('hex');
  const defaultEnvContent = `PORT=8080\nJWT_SECRET=${defaultSecret}\nDATABASE_PATH=devdeck.db\n`;
  try {
    fs.writeFileSync(envPath, defaultEnvContent, 'utf8');
  } catch (err) {
    // If writing fails (e.g. write-protected folder), fallback to in-memory env
    process.env.JWT_SECRET = process.env.JWT_SECRET || defaultSecret;
  }
}

// Load .env file
dotenv.config({ path: envPath });

// Hard fallback if JWT_SECRET still not set
if (!process.env.JWT_SECRET || process.env.JWT_SECRET.length < 8) {
  process.env.JWT_SECRET = crypto.randomBytes(32).toString('hex');
}

const envSchema = z.object({
  PORT: z.coerce.number().default(8080),
  JWT_SECRET: z.string().min(8, 'JWT_SECRET must be at least 8 characters long'),
  DATABASE_PATH: z.string().default('devdeck.db'),
  PAIRING_TOKEN: z.string().optional(),
  LOG_LEVEL: z.enum(['error', 'warn', 'info', 'http', 'verbose', 'debug', 'silly']).default('info'),
});

export type Env = z.infer<typeof envSchema>;

const result = envSchema.safeParse(process.env);

if (!result.success) {
  console.error('❌ Invalid environment variables:', result.error.format());
  process.exit(1);
}

export const env = result.data;
