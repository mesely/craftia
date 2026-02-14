export interface IProvider {
  id: string;
  businessName: string;
  phoneNumber: string;
  city: string;
  district: string;
  address?: string;
  lat: number;
  lng: number;
}

export interface ICrawlStats {
  totalFound: number;
  newlySaved: number;
  skipped: number;
}