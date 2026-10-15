import { BadRequestException, Injectable, ServiceUnavailableException, UnauthorizedException } from '@nestjs/common';
import { AccountEntity } from '../accounts/account.types';
import { AccountsService } from '../accounts/accounts.service';
import { ProvidersService } from '../providers/providers.service';
import { FirebaseLoginDto, LoginDto, RegisterDto } from './auth.dto';
import { FirebaseVerifier } from './firebase.verifier';
import { TokenService } from './token.service';

export interface Session {
  account: AccountEntity;
  token: string;
}

/** Sign-up and sign-in against the app's own database. No SMS / e-mail verification yet. */
@Injectable()
export class AuthService {
  constructor(
    private readonly accounts: AccountsService,
    private readonly providers: ProvidersService,
    private readonly tokens: TokenService,
    private readonly firebase: FirebaseVerifier,
  ) {}

  private session(account: AccountEntity): Session {
    return { account, token: this.tokens.issue(account.id) };
  }

  async register(dto: RegisterDto): Promise<Session> {
    if (dto.role === 'provider' && !dto.provider) throw new BadRequestException('Usta bilgileri eksik.');
    await this.accounts.assertAvailable(dto.email, dto.phone);
    const listing = dto.role === 'provider' ? await this.providers.create(dto.provider!) : null;
    const account = await this.accounts.register({
      role: dto.role,
      name: dto.name,
      phone: dto.phone,
      email: dto.email,
      password: dto.password,
      providerId: listing?.id ?? null,
    });
    return this.session(account);
  }

  async login(dto: LoginDto): Promise<Session> {
    const account = await this.accounts.verify(dto.identifier, dto.password);
    if (!account) {
      const known = await this.accounts.knows(dto.identifier);
      throw new UnauthorizedException(
        known ? 'Şifre yanlış. Lütfen tekrar dene.' : 'Bu bilgilerle kayıtlı hesap bulamadık. Önce kayıt olabilirsin.',
      );
    }
    return this.session(account);
  }

  /** A customer who decides to offer services keeps the same account. */
  async upgrade(accountId: string, provider: NonNullable<RegisterDto['provider']>): Promise<Session> {
    const current = await this.accounts.get(accountId);
    if (current.providerId) throw new BadRequestException('Zaten bir usta sayfan var.');
    const listing = await this.providers.create(provider);
    return this.session(await this.accounts.attachProvider(accountId, listing.id));
  }

  /** Which sign-in buttons are switched on. Password sign-in is always available. */
  methods() {
    return { password: true, ...this.firebase.methods() };
  }

  /**
   * Google / Apple / SMS sign-in through Firebase. Passive (503) until FIREBASE_PROJECT_ID is set.
   * Returns a session, or `needsProfile` when this is a new person who still has to pick a role.
   */
  async loginWithFirebase(dto: FirebaseLoginDto): Promise<Session | { needsProfile: true; suggested: { name: string; email: string; phone: string } }> {
    if (!this.firebase.enabled) throw new ServiceUnavailableException('Bu giriş yöntemi henüz etkin değil.');
    const identity = await this.firebase.verify(dto.idToken);
    if (!identity) throw new UnauthorizedException('Giriş doğrulanamadı. Lütfen tekrar dene.');
    const kind = identity.signInProvider === 'google.com' ? 'google' : identity.signInProvider === 'apple.com' ? 'apple' : identity.signInProvider === 'phone' ? 'phone' : null;
    if (!kind || !this.firebase.methods()[kind]) throw new ServiceUnavailableException('Bu giriş yöntemi henüz etkin değil.');

    const existing = await this.accounts.findFederated(identity);
    if (existing) return this.session(existing);

    const name = (dto.name ?? identity.name ?? '').trim();
    if (!dto.role || name.length < 2) {
      return { needsProfile: true, suggested: { name: identity.name ?? '', email: identity.email ?? '', phone: identity.phone ?? '' } };
    }
    if (dto.role === 'provider' && !dto.provider) throw new BadRequestException('Usta bilgileri eksik.');
    const listing = dto.role === 'provider' ? await this.providers.create(dto.provider!) : null;
    const account = await this.accounts.registerFederated({
      identity,
      role: dto.role,
      name,
      phone: dto.phone,
      email: dto.email,
      providerId: listing?.id ?? null,
    });
    return this.session(account);
  }

  me(accountId: string) {
    return this.accounts.get(accountId);
  }
}
