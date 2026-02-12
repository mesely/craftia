// src/provider/provider.interface.ts

export interface Provider {
  id?: string; // MongoDB'den gelince string olacak
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