import { Injectable, OnModuleInit, Inject } from '@nestjs/common';
import { ClientGrpc } from '@nestjs/microservices';

@Injectable()
export class ProviderService implements OnModuleInit {
  private providerServiceClient: any;

  // AppModule'da tanımladığımız 'PROVIDER_PACKAGE' ismini buraya Inject ediyoruz
  constructor(@Inject('PROVIDER_PACKAGE') private client: ClientGrpc) {}

  onModuleInit() {
    // provider.proto içindeki 'service ProviderService' tanımıyla aynı olmalı
    this.providerServiceClient = this.client.getService<any>('ProviderService');
  }

  createProvider(data: any) {
    return this.providerServiceClient.createProvider(data);
  }

  findAll() {
    return this.providerServiceClient.findAll({});
  }

  findOne(id: string) {
    return this.providerServiceClient.findOne({ id });
  }

  updateProvider(id: string, data: any) {
    return this.providerServiceClient.updateProvider({ id, ...data });
  }

  deleteProvider(id: string) {
    return this.providerServiceClient.deleteProvider({ id });
  }
}