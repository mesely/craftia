import { Page } from '../common/pagination';
import { ProviderEntity, ProviderQuery, ProviderView } from './provider.types';

/** What an usta may change on their own listing. */
export type ProviderProfilePatch = Partial<
  Pick<
    ProviderEntity,
    | 'about'
    | 'address'
    | 'serviceAreas'
    | 'phoneNumber'
    | 'portfolioImages'
    | 'priceList'
    | 'profileImage'
    | 'businessName'
    | 'city'
    | 'district'
    | 'lat'
    | 'lng'
  > & { featuredUntil: string | null }
>;

export abstract class ProvidersRepository {
  abstract list(query: ProviderQuery): Promise<Page<ProviderView>>;
  abstract findById(id: string, userLat?: number, userLng?: number): Promise<ProviderView | null>;
  abstract create(data: Omit<ProviderEntity, 'id'>): Promise<ProviderEntity>;
  abstract update(id: string, patch: ProviderProfilePatch): Promise<ProviderEntity | null>;
  abstract updateReviewStats(id: string, rating: number, reviewCount: number): Promise<void>;
}
