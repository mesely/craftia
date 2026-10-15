import { ServicePrice } from '../common/price';

export type SortMode = 'nearest' | 'rating' | 'recommended';

export interface ProviderEntity {
  id: string;
  businessName: string;
  phoneNumber: string;
  mainType: string;
  subType: string;
  city: string;
  district: string;
  address: string;
  lat: number | null;
  lng: number | null;
  rating: number;
  reviewCount: number;
  /** Paid placement: legacy flag, or an active promotion (see `featuredUntil`). */
  isPremium: boolean;
  /** ISO time the paid promotion ends; null when none is running. */
  featuredUntil: string | null;
  isVerified: boolean;
  about: string;
  profileImage: string | null;
  portfolioImages: string[];
  priceList: ServicePrice[];
  /** Districts the provider travels to. Empty when the source data does not say. */
  serviceAreas: string[];
  /** Present only on test records created through the demo sign-in. */
  isDemo?: boolean;
}

export interface ProviderView extends ProviderEntity {
  distanceKm: number | null;
}

export interface ProviderQuery {
  page: number;
  limit: number;
  mainType?: string;
  subType?: string;
  city?: string;
  sortMode: SortMode;
  distance?: number;
  userLat?: number;
  userLng?: number;
  q?: string;
  /** An usta never sees their own listing among the results. */
  excludeId?: string;
}
