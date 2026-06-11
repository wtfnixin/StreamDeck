import jwt from 'jsonwebtoken';
import { env } from '../core/config/env';
import { logger } from '../core/logger/winston';

export interface JWTPayload {
  deviceId: string;
  deviceName: string;
}

export class JWTService {
  private static readonly SECRET = env.JWT_SECRET;
  private static readonly EXPIRES_IN = '90d'; // 90 days token life for trusted remote controls

  public static issueJWT(payload: JWTPayload): string {
    try {
      return jwt.sign(payload, this.SECRET, { expiresIn: this.EXPIRES_IN });
    } catch (error) {
      logger.error('Failed to issue JWT token:', error);
      throw new Error('Token creation failed');
    }
  }

  public static verifyJWT(token: string): JWTPayload {
    try {
      return jwt.verify(token, this.SECRET) as JWTPayload;
    } catch (error) {
      logger.error('JWT validation failed:', error);
      throw new Error('Invalid or expired token');
    }
  }
}
