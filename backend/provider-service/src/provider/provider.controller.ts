import { Controller } from '@nestjs/common';
import { GrpcMethod } from '@nestjs/microservices';
import { ProviderService } from './provider.service';

@Controller()
export class ProviderController {
  constructor(private readonly providerService: ProviderService) {}

  @GrpcMethod('ProviderService', 'CreateProvider')
  async createProvider(data: any) {
    return this.providerService.create(data);
  }

  @GrpcMethod('ProviderService', 'FindAll')
  async findAll() {
    const providers = await this.providerService.findAll();
    return { providers };
  }

  @GrpcMethod('ProviderService', 'FindOne')
  async findOne(data: { id: string }) {
    return this.providerService.findOne(data.id);
  }

  @GrpcMethod('ProviderService', 'UpdateProvider')
  async updateProvider(data: any) {
    return this.providerService.update(data.id, data);
  }

  @GrpcMethod('ProviderService', 'DeleteProvider')
  async deleteProvider(data: { id: string }) {
    return this.providerService.delete(data.id);
  }
}