import { ConflictException, ForbiddenException, UnauthorizedException } from '@nestjs/common';
import { AccountsService } from '../src/accounts/accounts.service';
import { AttachmentsService } from '../src/attachments/attachments.service';
import { AuthGuard } from '../src/auth/auth.guard';
import { AuthService } from '../src/auth/auth.service';
import { FirebaseVerifier } from '../src/auth/firebase.verifier';
import { TokenService } from '../src/auth/token.service';
import { StoreFactory } from '../src/common/store';
import { MockProvidersRepository } from '../src/providers/providers.mock.repository';
import { ProvidersService } from '../src/providers/providers.service';

function setup() {
  const stores = new StoreFactory(undefined);
  const accounts = new AccountsService(stores);
  const providers = new ProvidersService(new MockProvidersRepository(), accounts, new AttachmentsService(stores));
  const tokens = new TokenService();
  const auth = new AuthService(accounts, providers, tokens, new FirebaseVerifier());
  const guard = new AuthGuard(tokens, accounts);
  return { accounts, auth, tokens, guard, stores };
}

const customer = { role: 'customer' as const, name: 'Ayşe Yılmaz', phone: '0532 123 45 67', email: 'Ayse@Example.com', password: 'gizli123' };

const provider = {
  businessName: 'Yıldız Elektrik',
  phoneNumber: '05329998877',
  mainType: 'TECHNICAL',
  subType: 'Elektrikçi',
  city: 'İzmir',
  district: 'Karşıyaka',
  about: 'Yıllardır bölgede elektrik işleri yapıyorum.',
};

function ctx(method: string, path: string, opts: { token?: string; body?: object; query?: object } = {}) {
  const req: any = {
    method,
    path,
    headers: opts.token ? { authorization: `Bearer ${opts.token}` } : {},
    body: opts.body ?? {},
    query: opts.query ?? {},
  };
  return { req, context: { switchToHttp: () => ({ getRequest: () => req }) } as any };
}

describe('accounts and sign-in', () => {
  it('registers straight into the database and never returns the password', async () => {
    const { auth, accounts } = setup();
    const s = await auth.register(customer);
    expect(s.account).toMatchObject({ name: 'Ayşe Yılmaz', email: 'ayse@example.com', phone: '05321234567', role: 'customer' });
    expect(JSON.stringify(s)).not.toMatch(/passwordHash|passwordSalt|gizli123/);
    expect(await accounts.find(s.account.id)).not.toHaveProperty('passwordHash');
  });

  it('signs in by e-mail or phone and rejects a wrong password with a clear message', async () => {
    const { auth } = setup();
    await auth.register(customer);
    expect((await auth.login({ identifier: 'AYSE@example.com', password: 'gizli123' })).account.name).toBe('Ayşe Yılmaz');
    expect((await auth.login({ identifier: '+90 532 123 45 67', password: 'gizli123' })).account.name).toBe('Ayşe Yılmaz');
    await expect(auth.login({ identifier: 'ayse@example.com', password: 'yanlis' })).rejects.toThrow('Şifre yanlış');
    await expect(auth.login({ identifier: 'yok@example.com', password: 'x' })).rejects.toThrow('kayıtlı hesap bulamadık');
  });

  it('does not allow a second account with the same e-mail or phone', async () => {
    const { auth } = setup();
    await auth.register(customer);
    await expect(auth.register({ ...customer, phone: '05550000000' })).rejects.toBeInstanceOf(ConflictException);
    await expect(auth.register({ ...customer, email: 'baska@example.com' })).rejects.toBeInstanceOf(ConflictException);
  });

  it('creates the listing together with an usta account, and upgrades a customer', async () => {
    const { auth } = setup();
    const usta = await auth.register({ ...customer, role: 'provider', email: 'usta@example.com', phone: '05329998877', provider });
    expect(usta.account.providerId).toBeTruthy();
    const c = await auth.register({ ...customer, email: 'c2@example.com', phone: '05320000000' });
    const upgraded = await auth.upgrade(c.account.id, provider);
    expect(upgraded.account).toMatchObject({ role: 'provider' });
    expect(upgraded.account.providerId).toBeTruthy();
    await expect(auth.upgrade(c.account.id, provider)).rejects.toThrow('Zaten');
  });

  it('locks an identifier after repeated wrong passwords', async () => {
    const { auth } = setup();
    await auth.register(customer);
    for (let i = 0; i < 8; i++) await expect(auth.login({ identifier: 'ayse@example.com', password: 'x' })).rejects.toBeInstanceOf(UnauthorizedException);
    await expect(auth.login({ identifier: 'ayse@example.com', password: 'gizli123' })).rejects.toThrow('Çok fazla');
  });
});

describe('session tokens', () => {
  it('verifies its own tokens and rejects tampered or expired ones', () => {
    const { tokens } = setup();
    const t = tokens.issue('acc-1');
    expect(tokens.verify(t)).toBe('acc-1');
    const [body, sig] = t.split('.');
    const forged = Buffer.from(JSON.stringify({ sub: 'acc-2', exp: Date.now() + 1e9 })).toString('base64url');
    expect(tokens.verify(`${forged}.${sig}`)).toBeNull();
    expect(tokens.verify(`${body}.AAAA`)).toBeNull();
    expect(tokens.verify(t, Date.now() + 91 * 86400000)).toBeNull();
    expect(tokens.verify('garbage')).toBeNull();
  });
});

describe('auth guard', () => {
  it('lets the public reads through and blocks everything else without a session', async () => {
    const { guard } = setup();
    for (const [m, p] of [['GET', '/providers'], ['GET', '/providers/69936e7ca52d8737b15c08ec'], ['GET', '/health'], ['POST', '/auth/login'], ['GET', '/promotions/plans']]) {
      await expect(guard.canActivate(ctx(m, p).context)).resolves.toBe(true);
    }
    await expect(guard.canActivate(ctx('POST', '/service-requests').context)).rejects.toBeInstanceOf(UnauthorizedException);
    await expect(guard.canActivate(ctx('GET', '/privacy/export', { query: { accountId: 'x' } }).context)).rejects.toBeInstanceOf(UnauthorizedException);
  });

  it('only lets people act as themselves', async () => {
    const { guard, tokens } = setup();
    const t = tokens.issue('me');
    await expect(guard.canActivate(ctx('POST', '/service-requests', { token: t, body: { userId: 'me' } }).context)).resolves.toBe(true);
    await expect(guard.canActivate(ctx('POST', '/service-requests', { token: t, body: { userId: 'someone-else' } }).context)).rejects.toBeInstanceOf(ForbiddenException);
    await expect(guard.canActivate(ctx('GET', '/privacy/export', { token: t, query: { accountId: 'someone-else' } }).context)).rejects.toBeInstanceOf(ForbiddenException);
    await expect(guard.canActivate(ctx('GET', '/accounts/someone-else', { token: t }).context)).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('only the managing account may read an usta inbox', async () => {
    const { guard, tokens, auth } = setup();
    const usta = await auth.register({ ...customer, role: 'provider', email: 'u@example.com', phone: '05329998877', provider });
    const other = await auth.register({ ...customer, email: 'o@example.com', phone: '05320000000' });
    const inbox = (token: string) =>
      guard.canActivate(ctx('GET', '/service-requests', { token, query: { providerId: usta.account.providerId! } }).context);
    await expect(inbox(usta.token)).resolves.toBe(true);
    await expect(inbox(other.token)).rejects.toBeInstanceOf(ForbiddenException);
    expect(tokens.verify(usta.token)).toBe(usta.account.id);
  });
});
