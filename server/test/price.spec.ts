import { isPriceRangeValid, parsePriceList, parsePriceValue } from '../src/common/price';

describe('price parsing', () => {
  it('parses min-max ranges', () => {
    expect(parsePriceValue('100-200')).toEqual({ minPrice: 100, maxPrice: 200 });
    expect(parsePriceValue('1.500 - 2.000 ₺')).toEqual({ minPrice: 1500, maxPrice: 2000 });
  });

  it('treats a single value as exact price', () => {
    expect(parsePriceValue('750')).toEqual({ minPrice: 750, maxPrice: 750 });
  });

  it('survives malformed legacy data', () => {
    expect(parsePriceValue('Arayınız')).toEqual({ minPrice: null, maxPrice: null });
    expect(parsePriceValue('')).toEqual({ minPrice: null, maxPrice: null });
    expect(parsePriceValue(undefined)).toEqual({ minPrice: null, maxPrice: null });
  });

  it('swaps reversed ranges', () => {
    expect(parsePriceValue('500-300')).toEqual({ minPrice: 300, maxPrice: 500 });
  });

  it('normalises maps, objects and arrays', () => {
    const expected = [{ serviceName: 'Boya', minPrice: 5000, maxPrice: 6000 }];
    expect(parsePriceList({ Boya: '5000-6000' })).toEqual(expected);
    expect(parsePriceList(new Map([['Boya', '5000-6000']]))).toEqual(expected);
    expect(parsePriceList(expected)).toEqual(expected);
    expect(parsePriceList(null)).toEqual([]);
  });

  it('applies the x2 / x1.5 / x1.3 ceiling rule', () => {
    expect(isPriceRangeValid(1000, 2000)).toBe(true);
    expect(isPriceRangeValid(1000, 2001)).toBe(false);
    expect(isPriceRangeValid(5000, 7500)).toBe(true);
    expect(isPriceRangeValid(5000, 7600)).toBe(false);
    expect(isPriceRangeValid(20000, 26000)).toBe(true);
    expect(isPriceRangeValid(100, 50)).toBe(false);
  });
});
