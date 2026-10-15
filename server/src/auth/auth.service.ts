import { BadRequestException, Injectable, UnauthorizedException } from '@nestjs/common';
import { AccountEntity } from '../accounts/account.types';
import { AccountsService } from '../accounts/accounts.service';
import { ProvidersService } from '../providers/providers.service';
import { LoginDto, RegisterDto } from './auth.dto';
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

  me(accountId: string) {
    return this.accounts.get(accountId);
  }
}
