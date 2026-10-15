export type AccountRole = 'customer' | 'provider';

/** A person using the app. Passwords never reach the server in the current (mock sign-in) stage. */
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
