import { db } from '../core/database/connection';
import { logger } from '../core/logger/winston';
import { WebsiteShortcut } from '../types/launcher';
import { openUrl } from '../utils/open';
import crypto from 'crypto';

export class WebsiteRegistryService {
  public static getAllWebsites(): WebsiteShortcut[] {
    try {
      const rows = db.prepare('SELECT * FROM websites').all() as any[];
      return rows.map(row => ({
        id: row.id,
        name: row.name,
        url: row.url,
        icon: row.icon ?? null,
      }));
    } catch (error) {
      logger.error('Failed to get websites from database:', error);
      return [];
    }
  }

  public static registerWebsite(web: Omit<WebsiteShortcut, 'id'> & { id?: string }): WebsiteShortcut {
    try {
      const id = web.id || crypto.randomUUID();
      const stmt = db.prepare(`
        INSERT INTO websites (id, name, url, icon)
        VALUES (?, ?, ?, ?)
        ON CONFLICT(id) DO UPDATE SET
          name = excluded.name,
          url = excluded.url,
          icon = excluded.icon
      `);
      stmt.run(id, web.name, web.url, web.icon ?? null);
      
      const registeredWeb: WebsiteShortcut = {
        id,
        name: web.name,
        url: web.url,
        icon: web.icon ?? null,
      };
      
      logger.info(`🌐 Website registered/updated: ${web.name} (${id})`);
      return registeredWeb;
    } catch (error) {
      logger.error('Failed to register website:', error);
      throw error;
    }
  }

  public static deleteWebsite(id: string): void {
    try {
      const stmt = db.prepare('DELETE FROM websites WHERE id = ?');
      stmt.run(id);
      logger.info(`🗑️ Website deleted: ${id}`);
    } catch (error) {
      logger.error(`Failed to delete website ${id}:`, error);
      throw error;
    }
  }

  public static launchWebsite(id: string): Promise<void> {
    return new Promise(async (resolve, reject) => {
      try {
        const row = db.prepare('SELECT url FROM websites WHERE id = ?').get(id) as { url: string } | undefined;
        if (!row) {
          logger.warn(`Attempted to launch website with unknown ID: ${id}`);
          return reject(new Error('Website not found in registry'));
        }

        const url = row.url;
        logger.info(`Opening website URL: ${url}`);
        
        await openUrl(url);
        resolve();
      } catch (error) {
        logger.error(`Exception during opening website ID ${id}:`, error);
        reject(error);
      }
    });
  }

  public static seedDefaults(): void {
    try {
      const countRow = db.prepare('SELECT count(*) as count FROM websites').get() as { count: number };
      if (countRow.count === 0) {
        logger.info('🌱 Seeding default websites...');
        const defaults = [
          { name: 'Google', url: 'https://www.google.com', icon: 'language' },
          { name: 'GitHub', url: 'https://github.com', icon: 'code' },
          { name: 'YouTube', url: 'https://www.youtube.com', icon: 'video_library' },
          { name: 'ChatGPT', url: 'https://chat.openai.com', icon: 'chat' }
        ];
        for (const web of defaults) {
          this.registerWebsite(web);
        }
      }
    } catch (error) {
      logger.error('Failed to seed default websites:', error);
    }
  }
}
