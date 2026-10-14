import { Page } from '../common/pagination';
import { ProviderEntity, ProviderQuery, ProviderView } from './provider.types';

export abstract class ProvidersRepository {
  abstract list(query: ProviderQuery): Promise<Page<ProviderView>>;
  abstract findById(id: string, userLat?: number, userLng?: number): Promise<ProviderView | null>;
  abstract create(data: Omit<ProviderEntity, 'id'>): Promise<ProviderEntity>;
  abstract updateReviewStats(id: string, rating: number, reviewCount: number): Promise<void>;
}
