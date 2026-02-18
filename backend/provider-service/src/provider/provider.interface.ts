// İsmine 'I' ekledik (IProvider yaptık) ve yeni alanları ekledik
export interface IProvider {
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
  
  // Eski alanlar (Frontend ve AI için şart)
  rating?: number;
  isPremium?: boolean;
  aiVerified?: boolean;
  lastAiAudit?: Date;
  createdAt?: Date;
  updatedAt?: Date;

  // ✅ YENİ EKLENEN RESİM VE FİYAT ALANLARI
  profileImage?: string;
  portfolioImages?: string[];
  priceList?: Record<string, string> | Map<string, string>; 
}

// Bu aynen kalıyor, dokunmuyoruz
export interface CrawlStats {
  totalFound: number;
  newlySaved: number;
  skipped: number;
}