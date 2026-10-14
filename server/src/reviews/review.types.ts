export interface ReviewEntity {
  id: string;
  providerId: string;
  authorName: string;
  rating: number;
  comment: string;
  tags: string[];
  createdAt: string;
}
