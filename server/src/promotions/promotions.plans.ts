/** "Öne çıkan" placement plans. Prices are in Turkish lira, tax included. Longer plans cost less per day. */
export interface PromotionPlan {
  id: 'week' | 'month' | 'quarter';
  days: number;
  priceTry: number;
  /** Shown as a quiet badge on the plan; never claims results. */
  badge: string | null;
}

export const PROMOTION_PLANS: readonly PromotionPlan[] = [
  { id: 'week', days: 7, priceTry: 99, badge: null },
  { id: 'month', days: 30, priceTry: 249, badge: 'En çok tercih edilen' },
  { id: 'quarter', days: 90, priceTry: 599, badge: 'En uygun günlük fiyat' },
];

export const findPlan = (id: string) => PROMOTION_PLANS.find((p) => p.id === id);
