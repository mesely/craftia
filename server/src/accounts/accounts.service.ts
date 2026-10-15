import { ConflictException, HttpException, HttpStatus, Injectable, NotFoundException } from '@nestjs/common';
import { Store, StoreFactory } from '../common/store';
import { hashPassword, verifyPassword } from '../auth/password';
import { AccountEntity, AccountRecord, AccountRole } from './account.types';
import { UpsertAccountDto } from './accounts.dto';

export const normalizePhone = (raw: string): string => {
  const digits = raw.replace(/\D/g, '');
  if (digits.length === 12 && digits.startsWith('90')) return `0${digits.slice(2)}`;
  if (digits.length === 10) return `0${digits}`;
  return digits;
};

/** An e-mail is compared in lower case, a phone number by its digits. */
export const normalizeIdentifier = (raw: string): { email?: string; phone?: string } => {
  const t = raw.trim().toLowerCase();
  return t.includes('@') ? { email: t } : { phone: normalizePhone(t) };
};

const strip = ({ passwordHash, passwordSalt, firebaseUid, ...account }: AccountRecord): AccountEntity => {
  void passwordHash;
  void firebaseUid;
  void passwordSalt;
  return account;
};

const MAX_FAILURES = 8;
const FAILURE_WINDOW_MS = 15 * 60 * 1000;

@Injectable()
export class AccountsService {
  private readonly store: Store<AccountRecord>;
  private readonly failures = new Map<string, { count: number; since: number }>();

  constructor(stores: StoreFactory) {
    this.store = stores.collection<AccountRecord>('app_accounts');
  }

  /** Profile-only write (no password): used by tests and internal flows. */
  async upsert(dto: UpsertAccountDto): Promise<AccountEntity> {
    const patch = {
      role: dto.role,
      name: dto.name.trim(),
      phone: dto.phone ? normalizePhone(dto.phone) : '',
      email: dto.email?.trim().toLowerCase() ?? '',
      providerId: dto.providerId ?? null,
    };
    if (await this.store.get(dto.id)) return strip((await this.store.update(dto.id, patch))!);
    const now = new Date().toISOString();
    return strip(
      await this.store.insert({
        id: dto.id,
        ...patch,
        emailVerified: false,
        phoneVerified: false,
        signInProvider: 'password',
        termsAcceptedAt: now,
        createdAt: now,
      }),
    );
  }

  private async byContact(email?: string, phone?: string): Promise<AccountRecord | null> {
    if (email) {
      const hit = (await this.store.find({ email }, { limit: 1 }))[0];
      if (hit) return hit;
    }
    if (phone) return (await this.store.find({ phone }, { limit: 1 }))[0] ?? null;
    return null;
  }

  /** Throws a friendly conflict when the e-mail or phone already belongs to somebody else. */
  async assertAvailable(email: string, phone: string, exceptId?: string): Promise<void> {
    const mail = email.trim().toLowerCase();
    const tel = phone ? normalizePhone(phone) : '';
    const existing = mail ? (await this.store.find({ email: mail }, { limit: 1 }))[0] : undefined;
    if (existing && existing.id !== exceptId) throw new ConflictException('Bu e-posta ile zaten bir hesap var. Giriş yapabilirsin.');
    const sameTel = tel ? (await this.store.find({ phone: tel }, { limit: 1 }))[0] : undefined;
    if (sameTel && sameTel.id !== exceptId) throw new ConflictException('Bu telefon numarasıyla zaten bir hesap var. Giriş yapabilirsin.');
  }

  async register(input: {
    role: AccountRole;
    name: string;
    phone: string;
    email: string;
    password: string;
    providerId?: string | null;
  }): Promise<AccountEntity> {
    await this.assertAvailable(input.email, input.phone);
    const { hash, salt } = await hashPassword(input.password);
    const now = new Date().toISOString();
    return strip(
      await this.store.insert({
        role: input.role,
        name: input.name.trim(),
        phone: input.phone ? normalizePhone(input.phone) : '',
        email: input.email.trim().toLowerCase(),
        providerId: input.providerId ?? null,
        passwordHash: hash,
        passwordSalt: salt,
        emailVerified: false,
        phoneVerified: false,
        signInProvider: 'password',
        termsAcceptedAt: now,
        createdAt: now,
      }),
    );
  }

  /** The account when the password is right; null otherwise. Repeated failures lock the identifier for a while. */
  async verify(identifier: string, password: string): Promise<AccountEntity | null> {
    const key = identifier.trim().toLowerCase();
    const now = Date.now();
    const f = this.failures.get(key);
    if (f && now - f.since < FAILURE_WINDOW_MS && f.count >= MAX_FAILURES) {
      throw new HttpException('Çok fazla hatalı deneme. Lütfen biraz bekleyip tekrar dene.', HttpStatus.TOO_MANY_REQUESTS);
    }
    const { email, phone } = normalizeIdentifier(identifier);
    const record = await this.byContact(email, phone);
    const ok = !!record?.passwordHash && !!record.passwordSalt && (await verifyPassword(password, record.passwordSalt, record.passwordHash));
    if (!ok) {
      const fresh = f && now - f.since < FAILURE_WINDOW_MS ? f : { count: 0, since: now };
      this.failures.set(key, { count: fresh.count + 1, since: fresh.since });
      return null;
    }
    this.failures.delete(key);
    return strip(record!);
  }

  /**
   * The account for a verified federated identity: by Firebase uid first, then by a *verified*
   * e-mail or phone (so a Google sign-in lands on the same person's existing account).
   */
  async findFederated(id: { uid: string; email: string | null; emailVerified: boolean; phone: string | null }): Promise<AccountEntity | null> {
    let rec = (await this.store.find({ firebaseUid: id.uid }, { limit: 1 }))[0] ?? null;
    if (!rec && id.email && id.emailVerified) rec = (await this.store.find({ email: id.email }, { limit: 1 }))[0] ?? null;
    if (!rec && id.phone) rec = (await this.store.find({ phone: normalizePhone(id.phone) }, { limit: 1 }))[0] ?? null;
    if (!rec) return null;
    const patch: Partial<AccountRecord> = { firebaseUid: id.uid };
    if (id.email && id.emailVerified && rec.email === id.email) patch.emailVerified = true;
    if (id.phone && rec.phone === normalizePhone(id.phone)) patch.phoneVerified = true;
    return strip((await this.store.update(rec.id, patch))!);
  }

  async registerFederated(input: {
    identity: { uid: string; email: string | null; emailVerified: boolean; phone: string | null; signInProvider: string };
    role: AccountRole;
    name: string;
    phone?: string;
    email?: string;
    providerId?: string | null;
  }): Promise<AccountEntity> {
    const email = (input.identity.email ?? input.email ?? '').trim().toLowerCase();
    const phone = input.identity.phone ? normalizePhone(input.identity.phone) : input.phone ? normalizePhone(input.phone) : '';
    await this.assertAvailable(email, phone);
    const now = new Date().toISOString();
    return strip(
      await this.store.insert({
        role: input.role,
        name: input.name.trim(),
        phone,
        email,
        providerId: input.providerId ?? null,
        firebaseUid: input.identity.uid,
        emailVerified: !!input.identity.email && input.identity.emailVerified,
        phoneVerified: !!input.identity.phone,
        signInProvider: input.identity.signInProvider,
        termsAcceptedAt: now,
        createdAt: now,
      }),
    );
  }

  async knows(identifier: string): Promise<boolean> {
    const { email, phone } = normalizeIdentifier(identifier);
    return !!(await this.byContact(email, phone));
  }

  async updateProfile(id: string, patch: { name?: string; phone?: string; email?: string }): Promise<AccountEntity> {
    await this.assertAvailable(patch.email ?? '', patch.phone ?? '', id);
    const set: Partial<AccountRecord> = {};
    if (patch.name !== undefined) set.name = patch.name.trim();
    if (patch.phone !== undefined) set.phone = normalizePhone(patch.phone);
    if (patch.email !== undefined) set.email = patch.email.trim().toLowerCase();
    const updated = await this.store.update(id, set);
    if (!updated) throw new NotFoundException('Hesap bulunamadı.');
    return strip(updated);
  }

  async attachProvider(id: string, providerId: string): Promise<AccountEntity> {
    const updated = await this.store.update(id, { role: 'provider', providerId });
    if (!updated) throw new NotFoundException('Hesap bulunamadı.');
    return strip(updated);
  }

  async get(id: string): Promise<AccountEntity> {
    const a = await this.store.get(id);
    if (!a) throw new NotFoundException('Hesap bulunamadı.');
    return strip(a);
  }

  async find(id: string): Promise<AccountEntity | null> {
    const a = await this.store.get(id);
    return a ? strip(a) : null;
  }

  async findByProviderId(providerId: string): Promise<AccountEntity | null> {
    const a = (await this.store.find({ providerId }, { limit: 1 }))[0];
    return a ? strip(a) : null;
  }

  remove(id: string): Promise<boolean> {
    return this.store.remove(id);
  }
}

