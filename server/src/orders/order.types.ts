export const REQUEST_STATUSES = ['PENDING', 'ACCEPTED', 'COMPLETED', 'CANCELLED'] as const;
export type RequestStatus = (typeof REQUEST_STATUSES)[number];

export interface ServiceRequestEntity {
  id: string;
  userId: string;
  providerId: string | null;
  providerName: string | null;
  mainType: string;
  subType: string;
  city: string;
  description: string;
  contactPhone: string;
  status: RequestStatus;
  lat: number | null;
  lng: number | null;
  createdAt: string;
}
