import { Injectable, OnModuleInit, Inject } from '@nestjs/common';
import { ClientGrpc } from '@nestjs/microservices';
import { firstValueFrom } from 'rxjs';

@Injectable()
export class ProviderGatewayService implements OnModuleInit {
  private providerService: any;

  constructor(@Inject('PROVIDER_PACKAGE') private client: ClientGrpc) {}

  onModuleInit() {
    // Mikroservisteki 'ProviderService' tanımına bağlanıyoruz
    this.providerService = this.client.getService<any>('ProviderService');
  }

  create(data: any) {
    return this.providerService.create(data);
  }

  findAll() {
    return this.providerService.findAll({});
  }

  findOne(id: string) {
    return this.providerService.findOne({ id });
  }

  update(id: string, data: any) {
    return this.providerService.update({ id, ...data });
  }

  delete(id: string) {
    return this.providerService.delete({ id });
  }

  getCities() {
    return this.providerService.getCities({});
  }

  getDistricts(city: string) {
    return this.providerService.getDistricts({ city });
  }

  getCategories() {
    return this.providerService.getCategories({});
  }

  // 🔥 Google Crawler'ı tetikleyen metod
  async startCrawl() {
    return await firstValueFrom(this.providerService.startGoogleCrawl({}));
  }
}