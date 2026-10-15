import { BadRequestException, ForbiddenException, HttpException, HttpStatus, Injectable, NotFoundException } from '@nestjs/common';
import { IsIn, IsOptional, IsString, MaxLength } from 'class-validator';
import { AccountsService } from '../accounts/accounts.service';
import { Store, StoreFactory } from '../common/store';
import { ProvidersService } from '../providers/providers.service';
import { findPlan, PROMOTION_PLANS } from './promotions.plans';

export class PurchasePromotionDto {
  @IsString() @MaxLength(64) actorId: string;
  @IsIn(PROMOTION_PLANS.map((p) => p.id)) planId: string;
  /** Store receipt (App Store / Google Play). Required when PAYMENTS_MODE=live. */
  @IsString() @MaxLength(8000) @IsOptional() receipt?: string;
}

interface PurchaseEntity {
  id: string;
  providerId: string;
  accountId: string;
  planId: string;
  days: number;
  priceTry: number;
  mode: 'test' | 'live';
  startsAt: string;
  endsAt: string;
  createdAt: string;
}

/**
 * Selling visibility. Until a store/payment provider is connected the server runs in `test` mode:
 * the promotion starts without charging anyone, and the API says so (`testMode: true`) so the app can
 * show it. In `live` mode a verified receipt is required; that verification is the one piece that
 * still has to be wired to App Store / Google Play before release (see docs/RELEASE.md).
 */
@Injectable()
export class PromotionsService {
  private readonly purchases: Store<PurchaseEntity>;

  constructor(
    stores: StoreFactory,
    private readonly providers: ProvidersService,
    private readonly accounts: AccountsService,
  ) {
    this.purchases = stores.collection<PurchaseEntity>('promotion_purchases');
  }

  private get mode(): 'test' | 'live' {
    return (process.env.PAYMENTS_MODE ?? 'test').toLowerCase() === 'live' ? 'live' : 'test';
  }

  plans() {
    return { testMode: this.mode === 'test', plans: PROMOTION_PLANS };
  }

  async purchase(providerId: string, dto: PurchasePromotionDto) {
    const account = await this.accounts.find(dto.actorId);
    if (!account || account.providerId !== providerId) throw new ForbiddenException('Bu sayfa için işlem yapma yetkin yok.');
    const plan = findPlan(dto.planId);
    if (!plan) throw new BadRequestException('Geçersiz plan.');
    if (this.mode === 'live' && !(await this.verifyReceipt(dto.receipt))) {
      throw new HttpException('Ödeme doğrulanamadı.', HttpStatus.PAYMENT_REQUIRED);
    }
    const current = await this.providers.get(providerId).catch(() => null);
    if (!current) throw new NotFoundException('Usta bulunamadı.');
    // Buying again while a promotion runs extends it instead of overlapping.
    const now = Date.now();
    const base = current.featuredUntil && new Date(current.featuredUntil).getTime() > now ? new Date(current.featuredUntil).getTime() : now;
    const endsAt = new Date(base + plan.days * 24 * 60 * 60 * 1000);
    await this.providers.setFeaturedUntil(providerId, endsAt);
    await this.purchases.insert({
      providerId,
      accountId: dto.actorId,
      planId: plan.id,
      days: plan.days,
      priceTry: plan.priceTry,
      mode: this.mode,
      startsAt: new Date(base).toISOString(),
      endsAt: endsAt.toISOString(),
      createdAt: new Date(now).toISOString(),
    });
    return { featuredUntil: endsAt.toISOString(), planId: plan.id, days: plan.days, testMode: this.mode === 'test' };
  }

  /** Placeholder for App Store / Google Play server-side receipt validation. */
  private async verifyReceipt(receipt?: string): Promise<boolean> {
    void receipt;
    return false;
  }
}
