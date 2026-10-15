import { generateKeyPairSync, createSign } from 'crypto';
import { ServiceUnavailableException, UnauthorizedException } from '@nestjs/common';
import { AccountsService } from '../src/accounts/accounts.service';
import { AttachmentsService } from '../src/attachments/attachments.service';
import { AuthService } from '../src/auth/auth.service';
import { FirebaseVerifier } from '../src/auth/firebase.verifier';
import { TokenService } from '../src/auth/token.service';
import { StoreFactory } from '../src/common/store';
import { MockProvidersRepository } from '../src/providers/providers.mock.repository';
import { ProvidersService } from '../src/providers/providers.service';

const PROJECT = 'usta-test';
const { publicKey, privateKey } = generateKeyPairSync('rsa', { modulusLength: 2048 });
const pem = publicKey.export({ type: 'spki', format: 'pem' }) as string;

function idToken(claims: Record<string, unknown>, opts: { kid?: string; key?: typeof privateKey } = {}) {
  const b64 = (o: unknown) => Buffer.from(JSON.stringify(o)).toString('base64url');
  const sec = Math.floor(Date.now() / 1000);
  const head = b64({ alg: 'RS256', kid: opts.kid ?? 'k1', typ: 'JWT' });
  const body = b64({ aud: PROJECT, iss: `https://securetoken.google.com/${PROJECT}`, sub: 'uid-1', iat: sec, exp: sec + 3600, ...claims });
  const sig = createSign('RSA-SHA256').update(`${head}.${body}`).sign(opts.key ?? privateKey).toString('base64url');
  return `${head}.${body}.${sig}`;
}

const google = { email: 'Ayse@Example.com', email_verified: true, name: 'Ayşe Yılmaz', firebase: { sign_in_provider: 'google.com' } };
const provider = { businessName: 'Yıldız Elektrik', phoneNumber: '05329998877', mainType: 'TECHNICAL', subType: 'Elektrikçi', city: 'İzmir', district: 'Karşıyaka', about: 'Yıllardır bölgede elektrik işleri yapıyorum.' };

function setup() {
  const stores = new StoreFactory(undefined);
  const accounts = new AccountsService(stores);
  const providers = new ProvidersService(new MockProvidersRepository(), accounts, new AttachmentsService(stores));
  const verifier = new FirebaseVerifier(async (kid) => (kid === 'k1' ? pem : null));
  return { accounts, verifier, auth: new AuthService(accounts, providers, new TokenService(), verifier) };
}

describe('Firebase sign-in (Google, Apple, SMS)', () => {
  afterEach(() => {
    delete process.env.FIREBASE_PROJECT_ID;
    delete process.env.AUTH_METHODS;
  });

  it('stays passive until a Firebase project is configured', async () => {
    const { auth } = setup();
    expect(auth.methods()).toEqual({ password: true, firebase: false, google: false, email: false, apple: false, phone: false });
    await expect(auth.loginWithFirebase({ idToken: idToken(google) })).rejects.toBeInstanceOf(ServiceUnavailableException);
  });

  it('switches methods on from the environment', () => {
    process.env.FIREBASE_PROJECT_ID = PROJECT;
    // Default: Google and e-mail. Apple and SMS stay off unless they are listed explicitly.
    expect(setup().auth.methods()).toEqual({ password: true, firebase: true, google: true, email: true, apple: false, phone: false });
    process.env.AUTH_METHODS = 'google';
    expect(setup().auth.methods()).toEqual({ password: true, firebase: true, google: true, email: false, apple: false, phone: false });
    process.env.AUTH_METHODS = 'google,email,apple,phone';
    expect(setup().auth.methods()).toMatchObject({ apple: true, phone: true });
  });

  it('asks a new person for a role first, then creates the account', async () => {
    process.env.FIREBASE_PROJECT_ID = PROJECT;
    const { auth } = setup();
    const first = await auth.loginWithFirebase({ idToken: idToken(google) });
    expect(first).toMatchObject({ needsProfile: true, suggested: { name: 'Ayşe Yılmaz', email: 'ayse@example.com' } });
    const session = await auth.loginWithFirebase({ idToken: idToken(google), role: 'customer' });
    expect('account' in session && session.account).toMatchObject({ role: 'customer', email: 'ayse@example.com', emailVerified: true, signInProvider: 'google.com' });
    // The same person coming back just signs in.
    const again = await auth.loginWithFirebase({ idToken: idToken(google) });
    expect('account' in again && again.account.name).toBe('Ayşe Yılmaz');
  });

  it('registers and signs in with Firebase e-mail + password, with the usta listing', async () => {
    process.env.FIREBASE_PROJECT_ID = PROJECT;
    const { auth } = setup();
    const mail = { email: 'usta@example.com', email_verified: false, sub: 'uid-mail', firebase: { sign_in_provider: 'password' } };
    const first = await auth.loginWithFirebase({ idToken: idToken(mail) });
    expect(first).toMatchObject({ needsProfile: true });
    const s = await auth.loginWithFirebase({ idToken: idToken(mail), role: 'provider', name: 'Ali Usta', phone: '05329998877', provider });
    expect('account' in s && s.account).toMatchObject({ role: 'provider', email: 'usta@example.com', emailVerified: false, signInProvider: 'password' });
    expect('account' in s && s.account.providerId).toBeTruthy();
    const again = await auth.loginWithFirebase({ idToken: idToken(mail) });
    expect('account' in again && again.account.name).toBe('Ali Usta');
    // Once Firebase reports the address verified, the account learns it.
    const verified = await auth.loginWithFirebase({ idToken: idToken({ ...mail, email_verified: true }) });
    expect('account' in verified && verified.account.emailVerified).toBe(true);
  });

  it('links Google to an e-mail account only when that account verified its address', async () => {
    process.env.FIREBASE_PROJECT_ID = PROJECT;
    const { auth } = setup();
    const mail = { email: 'ayse@example.com', email_verified: true, sub: 'uid-mail', firebase: { sign_in_provider: 'password' } };
    const created = await auth.loginWithFirebase({ idToken: idToken(mail), role: 'customer', name: 'Ayşe Yılmaz' });
    const s = await auth.loginWithFirebase({ idToken: idToken(google) });
    expect('account' in s && s.account.id).toBe('account' in created ? created.account.id : '');
  });

  it('never links by an unverified account e-mail (no pre-registration hijack)', async () => {
    process.env.FIREBASE_PROJECT_ID = PROJECT;
    const { auth } = setup();
    const mail = { email: 'ayse@example.com', email_verified: false, sub: 'uid-attacker', firebase: { sign_in_provider: 'password' } };
    await auth.loginWithFirebase({ idToken: idToken(mail), role: 'customer', name: 'Saldırgan' });
    const g = await auth.loginWithFirebase({ idToken: idToken(google) });
    expect(g).toMatchObject({ needsProfile: true });
    await expect(auth.loginWithFirebase({ idToken: idToken(google), role: 'customer' })).rejects.toBeDefined();
  });

  it('SMS sign-in works when explicitly switched on, and creates an usta with the listing', async () => {
    process.env.FIREBASE_PROJECT_ID = PROJECT;
    process.env.AUTH_METHODS = 'phone';
    const { auth } = setup();
    const sms = { phone_number: '+905329998877', firebase: { sign_in_provider: 'phone' }, sub: 'uid-sms' };
    const s = await auth.loginWithFirebase({ idToken: idToken(sms), role: 'provider', name: 'Ali Usta', provider });
    expect('account' in s && s.account).toMatchObject({ role: 'provider', phone: '05329998877', phoneVerified: true });
    expect('account' in s && s.account.providerId).toBeTruthy();
  });

  it('rejects forged, expired, wrong-project and unknown-key tokens', async () => {
    process.env.FIREBASE_PROJECT_ID = PROJECT;
    const { auth, verifier } = setup();
    const other = generateKeyPairSync('rsa', { modulusLength: 2048 });
    for (const bad of [
      idToken(google, { key: other.privateKey }),
      idToken({ ...google, exp: Math.floor(Date.now() / 1000) - 10 }),
      idToken({ ...google, aud: 'other-project' }),
      idToken(google, { kid: 'unknown' }),
      'not.a.token',
    ]) {
      expect(await verifier.verify(bad)).toBeNull();
      await expect(auth.loginWithFirebase({ idToken: bad.length < 20 ? bad.padEnd(24, 'x') : bad })).rejects.toBeInstanceOf(UnauthorizedException);
    }
  });

  it('keeps a disabled method off even with a valid token', async () => {
    process.env.FIREBASE_PROJECT_ID = PROJECT;
    process.env.AUTH_METHODS = 'phone';
    const { auth } = setup();
    await expect(auth.loginWithFirebase({ idToken: idToken(google) })).rejects.toBeInstanceOf(ServiceUnavailableException);
  });
});
