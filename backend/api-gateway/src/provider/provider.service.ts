import { Injectable, OnModuleInit, Inject } from '@nestjs/common';
import { ClientGrpc } from '@nestjs/microservices';
import { firstValueFrom } from 'rxjs';
// import { join } from 'path'; // Eğer proto path için lazımsa kalsın, yoksa silebilirsin.

@Injectable()
export class ProviderGatewayService implements OnModuleInit {
  private providerClient: any;

  constructor(@Inject('PROVIDER_PACKAGE') private client: ClientGrpc) {}

  onModuleInit() {
    // Proto dosyasındaki 'ProviderService' adıyla eşleşmeli
    this.providerClient = this.client.getService<any>('ProviderService');
  }

  async findAll(query: any) {
    const payload = {
      page: Number(query.page) || 1,
      limit: Number(query.limit) || 10,
      mainType: query.mainType || '',
      subType: query.subType || '',
      city: query.city || '',
      sort: query.sort || '',
      userLat: parseFloat(query.userLat) || 0,
      userLng: parseFloat(query.userLng) || 0,
      sortMode: query.sortMode || ''
    };

    return await firstValueFrom(this.providerClient.findAll(payload));
  }

  async findOne(id: string) {
    return await firstValueFrom(this.providerClient.findOne({ id }));
  }

  async getCities() {
    return await firstValueFrom(this.providerClient.getCities({}));
  }

  async startTurkeyGeneralCrawl() {
    return await firstValueFrom(this.providerClient.startTurkeyGeneralCrawl({}));
  }

  // ✅ YENİ EKLENEN: Usta Oluşturma Metodu
  async create(data: any) {
    // Frontend'den gelen veriyi gRPC payload'una (CreateProviderRequest) dönüştür
    const payload = {
      name: data.firstName && data.lastName ? `${data.firstName} ${data.lastName}` : data.name || '',
      businessName: data.businessName || '',
      phoneNumber: data.phoneNumber || data.phone || '',
      category: data.mainType || data.category || '',
      city: data.city || '',
      district: data.district || '',
      address: data.address || '',
      lat: parseFloat(data.lat) || 0,
      lng: parseFloat(data.lng) || 0,
      
      // YENİ RESİM VE FİYAT ALANLARI
      profileImage: data.profileImage || '',
      portfolioImages: data.portfolioImages || [],
      priceList: data.priceList || {}
    };

    // Microservice'e ilet ve cevabı bekle
    return await firstValueFrom(this.providerClient.create(payload));
  }
}