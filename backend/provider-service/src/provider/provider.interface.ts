export interface Provider {
  id: string;
  businessName: string;
  phoneNumber: string;
  city: string;
  district: string;
  lat: number;
  lng: number;
}

export interface CrawlStats {
  totalFound: number;
  newlySaved: number;
  skipped: number;
}