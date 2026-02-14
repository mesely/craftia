import { Injectable, OnModuleInit, Inject } from '@nestjs/common';
import { ClientGrpc } from '@nestjs/microservices';
import { lastValueFrom } from 'rxjs';

/**
 * PROVIDER GATEWAY SERVICE
 * Gateway ile Mikroservis (gRPC) arasındaki köprü.
 * REST isteklerini gRPC paketlerine dönüştürüp karşı tarafa fırlatır.
 */
@Injectable()
export class ProviderGatewayService implements OnModuleInit {
  private providerService: any;

  constructor(@Inject('PROVIDER_PACKAGE') private client: ClientGrpc) {}

  onModuleInit() {
    // Proto dosyasındaki 'ProviderService' tanımına bağlanıyoruz
    this.providerService = this.client.getService<any>('ProviderService');
  }

  create(data: any) {
    return this.providerService.Create(data);
  }

  /**
   * ✅ GÜNCELLENDİ: Filtre Paketi Aktarımı
   * Gateway Controller'dan gelen tüm filtreleri (page, city, userLat vb.) 
   * gRPC üzerinden Mikroservise (ProviderService) olduğu gibi iletir.
   */
  async findAll(filters: any) {
    try {
      // filters: { page, limit, mainType, subType, city, sort, userLat, userLng }
      // gRPC üzerinden Observable döner, lastValueFrom ile Promise'e çevirip bekliyoruz.
      return await lastValueFrom(this.providerService.FindAll(filters));
    } catch (error) {
      console.error('❌ FindAll gRPC Hatası:', error.message);
      return { providers: [], total: 0 };
    }
  }

  async findOne(id: string) {
    return await lastValueFrom(this.providerService.FindOne({ id }));
  }

  async update(id: string, data: any) {
    return await lastValueFrom(this.providerService.Update({ id, ...data }));
  }

  async delete(id: string) {
    return await lastValueFrom(this.providerService.Delete({ id }));
  }

  async getCities() {
    return await lastValueFrom(this.providerService.GetCities({}));
  }

  async getDistricts(city: string) {
    return await lastValueFrom(this.providerService.GetDistricts({ city }));
  }

  async getCategories() {
    return await lastValueFrom(this.providerService.GetCategories({}));
  }

  async startCrawl() {
    return await lastValueFrom(this.providerService.StartGoogleCrawl({}));
  }
}