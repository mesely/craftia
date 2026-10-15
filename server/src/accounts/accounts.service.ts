import { Injectable, NotFoundException } from '@nestjs/common';
import { Store, StoreFactory } from '../common/store';
import { AccountEntity } from './account.types';
import { UpsertAccountDto } from './accounts.dto';

@Injectable()
export class AccountsService {
  private readonly store: Store<AccountEntity>;

  constructor(stores: StoreFactory) {
    this.store = stores.collection<AccountEntity>('app_accounts');
  }

  /** The device-generated id is the primary key. */
  async upsert(dto: UpsertAccountDto): Promise<AccountEntity> {
    const patch = {
      role: dto.role,
      name: dto.name.trim(),
      phone: dto.phone?.replace(/[^\d+]/g, '') ?? '',
      email: dto.email?.trim().toLowerCase() ?? '',
      providerId: dto.providerId ?? null,
    };
    if (await this.store.get(dto.id)) return (await this.store.update(dto.id, patch))!;
    const now = new Date().toISOString();
    return this.store.insert({ id: dto.id, ...patch, termsAcceptedAt: now, createdAt: now });
  }

  async get(id: string): Promise<AccountEntity> {
    const a = await this.store.get(id);
    if (!a) throw new NotFoundException('Hesap bulunamadı.');
    return a;
  }

  find(id: string): Promise<AccountEntity | null> {
    return this.store.get(id);
  }

  async findByProviderId(providerId: string): Promise<AccountEntity | null> {
    return (await this.store.find({ providerId }, { limit: 1 }))[0] ?? null;
  }

  remove(id: string): Promise<boolean> {
    return this.store.remove(id);
  }
}
