import { CanActivate, ExecutionContext, ForbiddenException, Injectable, UnauthorizedException } from '@nestjs/common';
import type { Request } from 'express';
import { AccountsService } from '../accounts/accounts.service';
import { TokenService } from './token.service';

type Authed = Request & { accountId?: string };

/** Fields that name "who is acting". They must always be the signed-in account. */
const IDENTITY_FIELDS = ['actorId', 'userId', 'senderId', 'reporterId', 'viewerId', 'accountId', 'customerId'];

/** Public reads and the sign-in calls. Everything else needs a valid session. */
const PUBLIC: Array<{ method: string; test: RegExp }> = [
  { method: 'GET', test: /^\/health$/ },
  { method: 'GET', test: /^\/categories$/ },
  { method: 'GET', test: /^\/promotions\/plans$/ },
  { method: 'GET', test: /^\/providers(\/[a-f\d]{24}|\/[\w-]+)?$/ },
  { method: 'GET', test: /^\/providers\/[\w-]+\/reviews$/ },
  { method: 'GET', test: /^\/attachments\/[\w-]+$/ },
  { method: 'GET', test: /^\/auth\/methods$/ },
  { method: 'POST', test: /^\/auth\/(register|login|firebase)$/ },
];

@Injectable()
export class AuthGuard implements CanActivate {
  constructor(
    private readonly tokens: TokenService,
    private readonly accounts: AccountsService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const req = context.switchToHttp().getRequest<Authed>();
    const path = req.path.replace(/\/+$/, '') || '/';
    const isPublic = PUBLIC.some((p) => p.method === req.method && p.test.test(path));

    const header = req.headers.authorization ?? '';
    const accountId = header.startsWith('Bearer ') ? this.tokens.verify(header.slice(7).trim()) : null;
    if (accountId) req.accountId = accountId;
    if (isPublic) return true;
    if (!accountId) throw new UnauthorizedException('Oturum açman gerekiyor.');

    // Whoever the request says is acting must be the signed-in person.
    const sources = [req.body, req.query] as Array<Record<string, unknown> | undefined>;
    for (const source of sources) {
      for (const field of IDENTITY_FIELDS) {
        const value = source?.[field];
        if (typeof value === 'string' && value !== '' && value !== accountId) {
          throw new ForbiddenException('Bu işlem için yetkin yok.');
        }
      }
    }
    const idParam = /^\/accounts\/([^/]+)$/.exec(path)?.[1];
    if (idParam && idParam !== accountId) throw new ForbiddenException('Bu işlem için yetkin yok.');

    // An usta's inbox belongs to the account that manages that listing.
    const inboxFor = typeof req.query?.providerId === 'string' ? req.query.providerId : '';
    if (req.method === 'GET' && path === '/service-requests' && inboxFor) {
      const me = await this.accounts.find(accountId);
      if (me?.providerId !== inboxFor) throw new ForbiddenException('Bu işlem için yetkin yok.');
    }
    return true;
  }
}
