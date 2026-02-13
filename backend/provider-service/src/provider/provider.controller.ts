import { Controller } from '@nestjs/common';
import { GrpcMethod } from '@nestjs/microservices';
import { ProviderService } from './provider.service';

@Controller()
export class ProviderController {
  constructor(private readonly providerService: ProviderService) {}

  // 1. Yeni Usta Oluşturma
  @GrpcMethod('ProviderService', 'Create')
  create(data: any) {
    return this.providerService.create(data);
  }

  // 2. Tüm Ustaları Listeleme
  @GrpcMethod('ProviderService', 'FindAll')
  async findAll() {
    const providers = await this.providerService.findAll();
    // Proto dosyasındaki 'ProviderList' formatına (repeated providers) çeviriyoruz
    return { providers };
  }

  // 3. Tek Usta Bulma
  @GrpcMethod('ProviderService', 'FindOne')
  findOne(data: { id: string }) {
    return this.providerService.findOne(data.id);
  }

  // 4. Usta Güncelleme
  @GrpcMethod('ProviderService', 'Update')
  update(data: any) {
    // Proto'dan gelen veride 'id' ayrıştırılır
    const { id, ...rest } = data;
    return this.providerService.update(id, rest);
  }

  // 5. Usta Silme
  @GrpcMethod('ProviderService', 'Delete')
  delete(data: { id: string }) {
    return this.providerService.delete(data.id);
  }

  // --- Yardımcı Endpointler ---

  // 6. Şehirleri Getir
  @GrpcMethod('ProviderService', 'GetCities')
  async getCities() {
    const items = await this.providerService.getCities();
    // Proto dosyasındaki 'CityList' formatına (repeated items) çeviriyoruz
    return { items };
  }

  // 7. İlçeleri Getir
  @GrpcMethod('ProviderService', 'GetDistricts')
  async getDistricts(data: { city: string }) {
    const items = await this.providerService.getDistricts(data.city);
    // Proto dosyasındaki 'DistrictList' formatına (repeated items) çeviriyoruz
    return { items };
  }

  // 8. Kategorileri Getir
  @GrpcMethod('ProviderService', 'GetCategories')
  async getCategories() {
    const items = await this.providerService.getCategories();
    // Proto dosyasındaki 'CategoryList' formatına (repeated items) çeviriyoruz
    return { items };
  }

  // 🔥 9. Google Crawler Başlat
  @GrpcMethod('ProviderService', 'StartGoogleCrawl')
  async startGoogleCrawl() {
    return await this.providerService.startTurkeyGeneralCrawl();
  }
}