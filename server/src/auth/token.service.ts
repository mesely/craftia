import { Injectable, Logger } from '@nestjs/common';
import { createHmac, randomBytes, timingSafeEqual } from 'crypto';

const DAY = 24 * 60 * 60 * 1000;
export const TOKEN_LIFETIME_MS = 90 * DAY;

/**
 * Signed session tokens (HMAC-SHA256, `payload.signature`). The secret comes from AUTH_SECRET;
 * production refuses to start without one, development falls back to a random per-process secret
 * (so sessions end when the dev server restarts).
 */
@Injectable()
export class TokenService {
  private readonly secret: string;

  constructor() {
    const configured = process.env.AUTH_SECRET ?? '';
    if (configured.length >= 32) {
      this.secret = configured;
    } else if (process.env.NODE_ENV === 'production') {
      throw new Error('AUTH_SECRET (at least 32 characters) is required in production.');
    } else {
      this.secret = randomBytes(32).toString('hex');
      new Logger('Auth').warn('AUTH_SECRET is not set: using a temporary secret, sessions end on restart.');
    }
  }

  private sign(body: string): string {
    return createHmac('sha256', this.secret).update(body).digest('base64url');
  }

  issue(accountId: string, now = Date.now()): string {
    const body = Buffer.from(JSON.stringify({ sub: accountId, exp: now + TOKEN_LIFETIME_MS })).toString('base64url');
    return `${body}.${this.sign(body)}`;
  }

  /** The account id, or null when the token is malformed, tampered with or expired. */
  verify(token: string, now = Date.now()): string | null {
    const [body, signature] = token.split('.');
    if (!body || !signature) return null;
    const expected = Buffer.from(this.sign(body));
    const actual = Buffer.from(signature);
    if (expected.length !== actual.length || !timingSafeEqual(expected, actual)) return null;
    try {
      const { sub, exp } = JSON.parse(Buffer.from(body, 'base64url').toString('utf8'));
      return typeof sub === 'string' && typeof exp === 'number' && exp > now ? sub : null;
    } catch {
      return null;
    }
  }
}
