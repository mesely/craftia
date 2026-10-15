import { haversineKm, isValidCoordinate } from '../common/geo';
import { ProviderEntity, ProviderQuery, ProviderView } from './provider.types';

const norm = (s: string) => s.toLocaleLowerCase('tr-TR');

/**
 * Pure filter + sort used by the mock data source. The Mongo repository
 * mirrors these rules in its aggregation pipeline.
 *
 * Rules (same as the original Usta behaviour):
 *  - premium providers always come first;
 *  - "nearest" needs valid user coordinates, otherwise falls back to rating;
 *  - providers without valid coordinates sort last in "nearest" and are
 *    excluded when a distance limit is active.
 */
export function runProviderQuery(all: ProviderEntity[], query: ProviderQuery): ProviderView[] {
  const hasUserLocation = isValidCoordinate(query.userLat, query.userLng);
  const text = query.q ? norm(query.q.trim()) : '';

  let views: ProviderView[] = all.map((p) => ({
    ...p,
    distanceKm:
      hasUserLocation && isValidCoordinate(p.lat, p.lng)
        ? round1(haversineKm(query.userLat!, query.userLng!, p.lat!, p.lng!))
        : null,
  }));

  views = views.filter((p) => {
    if (query.mainType && norm(p.mainType) !== norm(query.mainType)) return false;
    if (query.subType && norm(p.subType) !== norm(query.subType)) return false;
    if (query.city && norm(p.city) !== norm(query.city)) return false;
    if (text) {
      const haystack = norm(`${p.businessName} ${p.subType} ${p.district} ${p.city}`);
      if (!haystack.includes(text)) return false;
    }
    if (query.distance != null && hasUserLocation) {
      if (p.distanceKm == null || p.distanceKm > query.distance) return false;
    }
    return true;
  });

  const nearest = query.sortMode === 'nearest' && hasUserLocation;
  views.sort((a, b) => {
    if (a.isPremium !== b.isPremium) return a.isPremium ? -1 : 1;
    if (nearest) {
      const da = a.distanceKm ?? Number.POSITIVE_INFINITY;
      const db = b.distanceKm ?? Number.POSITIVE_INFINITY;
      if (da !== db) return da - db;
    }
    if (a.rating !== b.rating) return b.rating - a.rating;
    if (a.reviewCount !== b.reviewCount) return b.reviewCount - a.reviewCount;
    return a.id.localeCompare(b.id);
  });
  return views;
}

const round1 = (n: number) => Math.round(n * 10) / 10;
