export interface Page<T> {
  items: T[];
  total: number;
  page: number;
  limit: number;
  hasMore: boolean;
}

export function toPage<T>(items: T[], total: number, page: number, limit: number): Page<T> {
  return { items, total, page, limit, hasMore: page * limit < total };
}
