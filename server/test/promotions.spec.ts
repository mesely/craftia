import { ForbiddenException } from '@nestjs/common';
import { AccountsService } from '../src/accounts/accounts.service';
import { AttachmentsService } from '../src/attachments/attachments.service';
import { StoreFactory } from '../src/common/store';
import { SEED_PROVIDERS } from '../src/data/seed';
import { PROMOTION_PLANS } from '../src/promotions/promotions.plans';
import { PromotionsService } from '../src/promotions/promotions.service';
import { MockProvidersRepository } from '../src/providers/providers.mock.repository';
import { ProvidersService } from '../src/providers/providers.service';

async function setup() {
  const stores = new StoreFactory(undefined);
  const accounts = new AccountsService(stores);
  const providers = new ProvidersService(new MockProvidersRepository(), accounts, new AttachmentsService(stores));
  const promotions = new PromotionsService(stores, providers, accounts);
  const target = SEED_PROVIDERS.find((p) => !p.isPremium)!;
  await accounts.upsert({ id: 'owner', role: 'provider', name: 'Usta', providerId: target.id });
  await accounts.upsert({ id: 'someone', role: 'customer', name: 'Biri' });
  return { promotions, providers, target };
}

const DAY = 24 * 60 * 60 * 1000;

describe('promotions', () => {
  it('has longer plans cost less per day', () => {
    const perDay = PROMOTION_PLANS.map((p) => p.priceTry / p.days);
    expect([...perDay].sort((a, b) => b - a)).toEqual(perDay);
  });

  it('makes the listing "Öne çıkan" for the plan length and runs in test mode by default', async () => {
    const { promotions, providers, target } = await setup();
    const res = await promotions.purchase(target.id, { actorId: 'owner', planId: 'month' });
    expect(res.testMode).toBe(true);
    const after = await providers.get(target.id);
    expect(after.isPremium).toBe(true);
    const days = (new Date(after.featuredUntil!).getTime() - Date.now()) / DAY;
    expect(days).toBeGreaterThan(29.9);
    expect(days).toBeLessThanOrEqual(30);
  });

  it('extends a running promotion instead of overlapping it', async () => {
    const { promotions, providers, target } = await setup();
    await promotions.purchase(target.id, { actorId: 'owner', planId: 'week' });
    await promotions.purchase(target.id, { actorId: 'owner', planId: 'week' });
    const after = await providers.get(target.id);
    const days = (new Date(after.featuredUntil!).getTime() - Date.now()) / DAY;
    expect(days).toBeGreaterThan(13.9);
  });

  it('only the account that manages the listing may buy for it', async () => {
    const { promotions, target } = await setup();
    await expect(promotions.purchase(target.id, { actorId: 'someone', planId: 'week' })).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('never lists an usta among their own results', async () => {
    const { providers, target } = await setup();
    const page = await providers.list({ page: 1, limit: 50, sortMode: 'rating', excludeId: target.id });
    expect(page.items.some((p) => p.id === target.id)).toBe(false);
  });
});
