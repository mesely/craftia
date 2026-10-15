import { Injectable, Optional } from '@nestjs/common';
import { createVerify } from 'crypto';

/** What a verified Firebase sign-in tells us about a person. */
export interface FederatedIdentity {
  uid: string;
  email: string | null;
  emailVerified: boolean;
  phone: string | null;
  name: string | null;
  /** `google.com`, `apple.com`, `phone`, `password` … (Firebase `sign_in_provider`). */
  signInProvider: string;
}

export type SignInMethod = 'google' | 'apple' | 'phone';

const CERTS_URL = 'https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com';

type KeyResolver = (kid: string) => Promise<string | null>;

/**
 * Verifies Firebase Authentication ID tokens (Google, Apple, SMS phone …) without the Firebase
 * Admin SDK: RS256 signature against Google's published certificates plus the standard claim
 * checks. It stays passive until FIREBASE_PROJECT_ID is set; then `AUTH_METHODS`
 * (default `google,apple,phone`) says which buttons are switched on.
 */
@Injectable()
export class FirebaseVerifier {
  private cache: { certs: Record<string, string>; until: number } | null = null;

  constructor(@Optional() private readonly resolveKey?: KeyResolver) {}

  get projectId(): string {
    return (process.env.FIREBASE_PROJECT_ID ?? '').trim();
  }

  get enabled(): boolean {
    return this.projectId.length > 0;
  }

  methods(): Record<SignInMethod, boolean> {
    const on = this.enabled
      ? (process.env.AUTH_METHODS ?? 'google,apple,phone').split(',').map((m) => m.trim().toLowerCase())
      : [];
    return { google: on.includes('google'), apple: on.includes('apple'), phone: on.includes('phone') };
  }

  private async certFor(kid: string): Promise<string | null> {
    if (this.resolveKey) return this.resolveKey(kid);
    const now = Date.now();
    if (!this.cache || this.cache.until < now) {
      const res = await fetch(CERTS_URL);
      if (!res.ok) return null;
      const maxAge = /max-age=(\d+)/.exec(res.headers.get('cache-control') ?? '')?.[1];
      this.cache = { certs: (await res.json()) as Record<string, string>, until: now + Number(maxAge ?? 3600) * 1000 };
    }
    return this.cache.certs[kid] ?? null;
  }

  /** The identity behind [idToken], or null when it is not a valid, current token for this project. */
  async verify(idToken: string, now = Date.now()): Promise<FederatedIdentity | null> {
    if (!this.enabled) return null;
    const parts = idToken.split('.');
    if (parts.length !== 3) return null;
    try {
      const header = JSON.parse(Buffer.from(parts[0], 'base64url').toString('utf8'));
      if (header.alg !== 'RS256' || typeof header.kid !== 'string') return null;
      const key = await this.certFor(header.kid);
      if (!key) return null;
      const ok = createVerify('RSA-SHA256').update(`${parts[0]}.${parts[1]}`).verify(key, Buffer.from(parts[2], 'base64url'));
      if (!ok) return null;
      const c = JSON.parse(Buffer.from(parts[1], 'base64url').toString('utf8'));
      const pid = this.projectId;
      const sec = Math.floor(now / 1000);
      if (c.aud !== pid || c.iss !== `https://securetoken.google.com/${pid}`) return null;
      if (typeof c.sub !== 'string' || !c.sub || typeof c.exp !== 'number' || c.exp <= sec) return null;
      if (typeof c.iat === 'number' && c.iat > sec + 300) return null;
      return {
        uid: c.sub,
        email: typeof c.email === 'string' ? c.email.toLowerCase() : null,
        emailVerified: c.email_verified === true,
        phone: typeof c.phone_number === 'string' ? c.phone_number : null,
        name: typeof c.name === 'string' ? c.name : null,
        signInProvider: typeof c.firebase?.sign_in_provider === 'string' ? c.firebase.sign_in_provider : 'unknown',
      };
    } catch {
      return null;
    }
  }
}
