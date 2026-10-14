import { Injectable } from '@nestjs/common';
import { randomUUID } from 'crypto';
import { Page, toPage } from '../common/pagination';
import { isValidCoordinate, haversineKm } from '../common/geo';
import { SEED_PROVIDERS } from '../data/seed';
import { runProviderQuery } from './provider.query';
import { ProviderEntity, ProviderQuery, ProviderView } from './provider.types';
import { ProvidersRepository } from './providers.repository';

@Injectable()
export class MockProvidersRepository extends ProvidersRepository {
  private readonly providers: ProviderEntity[] = SEED_PROVIDERS.map((p) => ({ ...p }));

  async list(query: ProviderQuery): Promise<Page<ProviderView>> {
    const all = runProviderQuery(this.providers, query);
    const start = (query.page - 1) * query.limit;
    return toPage(all.slice(start, start + query.limit), all.length, query.page, query.limit);
  }

  async findById(id: string, userLat?: number, userLng?: number): Promise<ProviderView | null> {
    const p = this.providers.find((e) => e.id === id);
    if (!p) return null;
    const located = isValidCoordinate(userLat, userLng) && isValidCoordinate(p.lat, p.lng);
    return {
      ...p,
      distanceKm: located ? Math.round(haversineKm(userLat!, userLng!, p.lat!, p.lng!) * 10) / 10 : null,
    };
  }

  async create(data: Omit<ProviderEntity, 'id'>): Promise<ProviderEntity> {
    const entity = { ...data, id: `p-${randomUUID().slice(0, 8)}` };
    this.providers.push(entity);
    return entity;
  }

  async updateReviewStats(id: string, rating: number, reviewCount: number): Promise<void> {
    const p = this.providers.find((e) => e.id === id);
    if (p) {
      p.rating = rating;
      p.reviewCount = reviewCount;
    }
  }
}
