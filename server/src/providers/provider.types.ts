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
  isPremium: boolean;
  isVerified: boolean;
  about: string;
  profileImage: string | null;
  portfolioImages: string[];
  priceList: ServicePrice[];
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
}
