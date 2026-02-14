export interface Provider {
  id?: string;
  _id?: any; // MongoDB'den gelen orijinal ID
  user?: any;
  businessName: string;
  phoneNumber: string;
  city: string;
  district: string;
  address?: string;
  website?: string;
  mainType?: string;
  subType?: string;
  lat: number;
  lng: number;
  openingFee?: number;
  pricePerUnit?: number;
  
  // ✅ YENİ EKLENEN ALANLAR (Frontend ve AI için şart)
  rating?: number;
  isPremium?: boolean;
  aiVerified?: boolean;
  lastAiAudit?: Date;
  createdAt?: Date;
  updatedAt?: Date;
}

export interface CrawlStats {
  totalFound: number;
  newlySaved: number;
  skipped: number;
}