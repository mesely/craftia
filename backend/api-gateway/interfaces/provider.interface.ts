import { Observable } from 'rxjs';

// --- Veri Tipleri (Provider Service ile BİREBİR AYNI) ---
export interface Provider {
  id?: string;
  first_name: string;
  last_name: string;
  phone: string;
  email: string;
  tags: string[];
}

export interface ProviderList {
  providers: Provider[];
}

export interface CreateProviderRequest {
  first_name: string;
  last_name: string;
  phone: string;
  email: string;
  tags: string[];
}

export interface UpdateProviderRequest {
  id: string;
  first_name?: string;
  last_name?: string;
  phone?: string;
  email?: string;
  tags?: string[];
}

export interface ProviderIdRequest {
  id: string;
}

// --- gRPC Client Servis Tanımı ---
export interface ProviderGrpcService {
  createProvider(data: CreateProviderRequest): Observable<Provider>;
  findAll(data: any): Observable<ProviderList>;
  findOne(data: ProviderIdRequest): Observable<Provider>;
  updateProvider(data: UpdateProviderRequest): Observable<Provider>;
  deleteProvider(data: ProviderIdRequest): Observable<Provider>;
}