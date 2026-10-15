import { MemoryStore } from '../src/common/store';

describe('MemoryStore filter', () => {
  it('supports equality, $in, $gt and sorting', async () => {
    const s = new MemoryStore<{ id: string; a: string; n: number }>();
    await s.insert({ a: 'x', n: 1 });
    await s.insert({ a: 'y', n: 2 });
    await s.insert({ a: 'x', n: 3 });
    expect((await s.find({ a: 'x' }, { sort: { n: -1 } })).map((d) => d.n)).toEqual([3, 1]);
    expect(await s.find({ a: { $in: ['y'] } })).toHaveLength(1);
    expect(await s.find({ n: { $gt: 1 } })).toHaveLength(2);
    expect(await s.removeWhere({ a: 'x' })).toBe(2);
  });
});
