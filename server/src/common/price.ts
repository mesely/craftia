export interface ServicePrice {
  serviceName: string;
  minPrice: number | null;
  maxPrice: number | null;
}

function toNumber(value: unknown): number | null {
  if (typeof value === 'number') return Number.isFinite(value) && value > 0 ? value : null;
  if (typeof value !== 'string') return null;
  const cleaned = value.replace(/[^\d.,]/g, '').replace(/\./g, '').replace(',', '.');
  const n = Number(cleaned);
  return Number.isFinite(n) && n > 0 ? n : null;
}

/** Parses legacy values like "100-200", "1.500 - 2.000 ₺", "850" or "Arayınız". */
export function parsePriceValue(raw: unknown): { minPrice: number | null; maxPrice: number | null } {
  if (typeof raw === 'number') {
    const n = toNumber(raw);
    return { minPrice: n, maxPrice: n };
  }
  if (typeof raw !== 'string') return { minPrice: null, maxPrice: null };
  const parts = raw.split(/[-–—]/);
  const min = toNumber(parts[0]);
  const max = parts.length > 1 ? toNumber(parts[1]) : min;
  if (min != null && max != null && max < min) return { minPrice: max, maxPrice: min };
  return { minPrice: min, maxPrice: max ?? min };
}

/**
 * Normalises every shape the price list has had: a Map/object of
 * {"Service": "min-max"}, or an already structured array.
 */
export function parsePriceList(raw: unknown): ServicePrice[] {
  if (raw == null) return [];
  if (Array.isArray(raw)) {
    return raw
      .filter((e) => e && typeof e === 'object' && typeof (e as any).serviceName === 'string')
      .map((e: any) => ({
        serviceName: e.serviceName.trim(),
        minPrice: toNumber(e.minPrice),
        maxPrice: toNumber(e.maxPrice),
      }))
      .filter((e) => e.serviceName.length > 0);
  }
  const entries: [string, unknown][] =
    raw instanceof Map ? [...raw.entries()] : typeof raw === 'object' ? Object.entries(raw as object) : [];
  return entries
    .filter(([name]) => name.trim().length > 0)
    .map(([name, value]) => ({ serviceName: name.trim(), ...parsePriceValue(value) }));
}

/** Highest allowed max price for a given min price (original Usta rule: x2 / x1.5 / x1.3). */
export function maxAllowedPrice(min: number): number {
  if (min <= 2000) return min * 2;
  if (min <= 10000) return min * 1.5;
  return min * 1.3;
}

export function isPriceRangeValid(min: number, max: number): boolean {
  return min > 0 && max >= min && max <= maxAllowedPrice(min);
}
