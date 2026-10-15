import { haversineKm, isValidCoordinate } from '../src/common/geo';
import { SEED_PROVIDERS } from '../src/data/seed';
import { runProviderQuery } from '../src/providers/provider.query';
import { ProviderQuery } from '../src/providers/provider.types';

const base: ProviderQuery = { page: 1, limit: 50, sortMode: 'nearest' };

describe('geo', () => {
  it('computes known distances', () => {
    // Istanbul -> Ankara is roughly 350 km
    const d = haversineKm(41.0082, 28.9784, 39.9334, 32.8597);
    expect(d).toBeGreaterThan(340);
    expect(d).toBeLessThan(360);
  });

  it('never treats (0,0) or garbage as a location', () => {
    expect(isValidCoordinate(0, 0)).toBe(false);
    expect(isValidCoordinate(NaN, 10)).toBe(false);
    expect(isValidCoordinate(91, 10)).toBe(false);
    expect(isValidCoordinate(undefined, undefined)).toBe(false);
    expect(isValidCoordinate(41, 29)).toBe(true);
  });
});

describe('runProviderQuery', () => {
  it('filters by category, subType and city', () => {
    const res = runProviderQuery(SEED_PROVIDERS, { ...base, mainType: 'TECHNICAL', subType: 'Elektrikçi', city: 'İstanbul' });
    expect(res.length).toBeGreaterThan(0);
    expect(res.every((p) => p.mainType === 'TECHNICAL' && p.subType === 'Elektrikçi' && p.city === 'İstanbul')).toBe(true);
  });

  it('puts premium first, then nearest', () => {
    const res = runProviderQuery(SEED_PROVIDERS, { ...base, userLat: 41.0082, userLng: 28.9784 });
    const firstNonPremium = res.findIndex((p) => !p.isPremium);
    expect(res.slice(firstNonPremium).every((p) => !p.isPremium)).toBe(true);
    const normal = res.filter((p) => !p.isPremium && p.distanceKm != null);
    for (let i = 1; i < normal.length; i++) expect(normal[i].distanceKm!).toBeGreaterThanOrEqual(normal[i - 1].distanceKm!);
  });

  it('respects the distance limit and ignores it without coordinates', () => {
    const near = runProviderQuery(SEED_PROVIDERS, { ...base, userLat: 41.0082, userLng: 28.9784, distance: 15 });
    expect(near.every((p) => p.distanceKm != null && p.distanceKm <= 15)).toBe(true);
    const noGps = runProviderQuery(SEED_PROVIDERS, { ...base, distance: 15 });
    expect(noGps.length).toBe(SEED_PROVIDERS.length);
    expect(noGps.every((p) => p.distanceKm === null)).toBe(true);
  });

  it('falls back to rating order when nearest has no coordinates', () => {
    const res = runProviderQuery(SEED_PROVIDERS, base).filter((p) => !p.isPremium);
    for (let i = 1; i < res.length; i++) expect(res[i].rating).toBeLessThanOrEqual(res[i - 1].rating);
  });

  it('searches by text (Turkish locale)', () => {
    const res = runProviderQuery(SEED_PROVIDERS, { ...base, q: 'marangoz' });
    expect(res.length).toBeGreaterThan(0);
  });
});
