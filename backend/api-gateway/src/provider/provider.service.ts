import { Injectable, OnModuleInit, Inject } from '@nestjs/common';
import { ClientGrpc } from '@nestjs/microservices';
import { firstValueFrom } from 'rxjs'; // ✅ Hata veren import buydu
import { join } from 'path';

@Injectable()
export class ProviderGatewayService implements OnModuleInit {
  private providerClient: any; // ✅ Property hatasını bu satır çözer

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

    // gRPC çağrısını yap ve Promise'e çevir
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
}