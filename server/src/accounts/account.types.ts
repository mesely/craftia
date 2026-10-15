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
  termsAcceptedAt: string;
  createdAt: string;
}

/** What is stored: the account plus a salted scrypt hash of the password. */
export interface AccountRecord extends AccountEntity {
  passwordHash?: string;
  passwordSalt?: string;
}
