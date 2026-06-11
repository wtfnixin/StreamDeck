import { db } from '../core/database/connection';
import { logger } from '../core/logger/winston';

export interface DeviceRecord {
  id: string;
  name: string;
  paired_at: string;
  last_connected_at: string | null;
  token_hash: string;
}

export class DeviceRepository {
  public static saveTrustedDevice(id: string, name: string, tokenHash: string): void {
    try {
      const stmt = db.prepare(`
        INSERT INTO trusted_devices (id, name, token_hash)
        VALUES (?, ?, ?)
        ON CONFLICT(id) DO UPDATE SET
          name = excluded.name,
          token_hash = excluded.token_hash,
          paired_at = CURRENT_TIMESTAMP
      `);
      stmt.run(id, name, tokenHash);
      logger.info(`📱 Device saved/updated in trusted_devices: ${name} (${id})`);
    } catch (error) {
      logger.error(`Failed to save trusted device ${id}:`, error);
      throw error;
    }
  }

  public static getTrustedDevice(id: string): DeviceRecord | null {
    try {
      const stmt = db.prepare('SELECT * FROM trusted_devices WHERE id = ?');
      const row = stmt.get(id) as DeviceRecord | undefined;
      return row || null;
    } catch (error) {
      logger.error(`Failed to get trusted device ${id}:`, error);
      return null;
    }
  }

  public static isDeviceTrusted(id: string): boolean {
    const device = this.getTrustedDevice(id);
    return device !== null;
  }

  public static updateLastConnected(id: string): void {
    try {
      const stmt = db.prepare('UPDATE trusted_devices SET last_connected_at = CURRENT_TIMESTAMP WHERE id = ?');
      stmt.run(id);
    } catch (error) {
      logger.error(`Failed to update last connected time for device ${id}:`, error);
    }
  }

  public static revokeDevice(id: string): void {
    try {
      const stmt = db.prepare('DELETE FROM trusted_devices WHERE id = ?');
      stmt.run(id);
      logger.info(`📱 Device revoked: ${id}`);
    } catch (error) {
      logger.error(`Failed to revoke device ${id}:`, error);
      throw error;
    }
  }

  public static getAllTrustedDevices(): DeviceRecord[] {
    try {
      const stmt = db.prepare('SELECT * FROM trusted_devices');
      return stmt.all() as DeviceRecord[];
    } catch (error) {
      logger.error('Failed to get all trusted devices:', error);
      return [];
    }
  }
}
