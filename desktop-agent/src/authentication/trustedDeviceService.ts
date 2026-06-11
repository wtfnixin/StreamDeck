import { JWTService } from './jwtService';
import { DeviceRepository } from '../repositories/deviceRepository';
import { logger } from '../core/logger/winston';

export class TrustedDeviceService {
  public static validateDeviceToken(token: string): { valid: boolean; deviceId?: string; deviceName?: string; error?: string } {
    try {
      if (!token) {
        return { valid: false, error: 'Token missing' };
      }

      const decoded = JWTService.verifyJWT(token);
      
      // Verify in SQLite repository
      const isTrusted = DeviceRepository.isDeviceTrusted(decoded.deviceId);
      if (!isTrusted) {
        logger.warn(`⚠️ Connection rejected: Device ${decoded.deviceName} (${decoded.deviceId}) is not trusted in DB.`);
        return { valid: false, error: 'Device is no longer trusted' };
      }

      // Update last connected time
      DeviceRepository.updateLastConnected(decoded.deviceId);

      return {
        valid: true,
        deviceId: decoded.deviceId,
        deviceName: decoded.deviceName,
      };
    } catch (error) {
      logger.error('Token validation failed in TrustedDeviceService:', error);
      return { valid: false, error: 'Invalid or expired token' };
    }
  }
}
