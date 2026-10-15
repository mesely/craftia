export type AccountRole = 'customer' | 'provider';

/** A person using the app, as the API shows them. Credentials never leave the server. */
export interface AccountEntity {
  id: string;
  role: AccountRole;
  name: string;
  phone: string;
  email: string;
  /** The `providers` document this account manages (usta accounts only). */
  providerId: string | null;
  /** Verified by a trusted sign-in (Firebase). Plain password sign-ups are unverified for now. */
  emailVerified: boolean;
  phoneVerified: boolean;
  /** `password`, `google.com`, `apple.com`, `phone` … */
  signInProvider: string;
  termsAcceptedAt: string;
  createdAt: string;
}

/** What is stored: the account plus a salted scrypt hash of the password. */
export interface AccountRecord extends AccountEntity {
  firebaseUid?: string;
  passwordHash?: string;
  passwordSalt?: string;
}
