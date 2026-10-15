import { isValidCoordinate } from '../common/geo';
import { parsePriceList } from '../common/price';
import { ProviderEntity } from './provider.types';

/** Maps a raw (possibly legacy) `providers` document to the API entity. Pure: no Nest or Mongoose imports. */
export function toProviderEntity(doc: any): ProviderEntity {
  const located = isValidCoordinate(doc.lat, doc.lng);
  return {
    id: String(doc._id),
    businessName: doc.businessName ?? '',
    phoneNumber: doc.phoneNumber ?? '',
    mainType: doc.mainType ?? '',
    subType: doc.subType ?? '',
    city: doc.city ?? '',
    district: doc.district ?? '',
    address: doc.address ?? '',
    lat: located ? doc.lat : null,
    lng: located ? doc.lng : null,
    rating: typeof doc.rating === 'number' ? doc.rating : 0,
    reviewCount: typeof doc.reviewCount === 'number' ? doc.reviewCount : 0,
    isPremium: doc.isPremium === true,
    isVerified: doc.aiVerified === true,
    about: doc.about ?? '',
    profileImage: doc.profileImage || null,
    portfolioImages: Array.isArray(doc.portfolioImages) ? doc.portfolioImages.filter(Boolean) : [],
    priceList: parsePriceList(doc.priceList),
    serviceAreas: Array.isArray(doc.serviceAreas) ? doc.serviceAreas.filter((a: unknown) => typeof a === 'string' && a.trim()) : [],
  };
}
