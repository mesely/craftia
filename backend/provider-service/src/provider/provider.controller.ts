import { Controller } from '@nestjs/common';
import { GrpcMethod } from '@nestjs/microservices';
import { ProviderService } from './provider.service';

@Controller()
export class ProviderController {
  constructor(private readonly providerService: ProviderService) {}

  @GrpcMethod('ProviderService', 'Create')
  create(data: any) { return this.providerService.create(data); }

  // ✅ DÜZELTİLDİ: Proto'daki FindAllRequest ile birebir eşleşen payload'u alır ve Servise paslar.
  @GrpcMethod('ProviderService', 'FindAll')
  async findAll(data: { 
    page?: number; 
    limit?: number; 
    mainType?: string;
    subType?: string; 
    city?: string; 
    sort?: string;
    userLat?: number;
    userLng?: number;
  }) { 
    // Gateway'den gelen tüm filtreleri (data objesi) direkt ProviderService'e (payload olarak) yolluyoruz.
    return await this.providerService.findAll(data);
  }

  @GrpcMethod('ProviderService', 'FindOne')
  findOne(data: { id: string }) { return this.providerService.findOne(data.id); }

  @GrpcMethod('ProviderService', 'Update')
  update(data: any) {
    const { id, ...rest } = data;
    return this.providerService.update(id, rest);
  }

  @GrpcMethod('ProviderService', 'Delete')
  delete(data: { id: string }) { return this.providerService.delete(data.id); }

  @GrpcMethod('ProviderService', 'GetCities')
  async getCities() {
    const items = await this.providerService.getCities();
    return { items };
  }

  @GrpcMethod('ProviderService', 'GetDistricts')
  async getDistricts(data: { city: string }) {
    const items = await this.providerService.getDistricts(data.city);
    return { items };
  }

  @GrpcMethod('ProviderService', 'GetCategories')
  async getCategories() {
    const items = await this.providerService.getCategories();
    return { items };
  }

  @GrpcMethod('ProviderService', 'StartGoogleCrawl')
  async startGoogleCrawl() {
    return await this.providerService.startTurkeyGeneralCrawl();
  }
}