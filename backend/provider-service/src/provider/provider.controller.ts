import { Controller } from '@nestjs/common';
import { GrpcMethod } from '@nestjs/microservices';
import { ProviderService } from './provider.service';

@Controller()
export class ProviderController {
  constructor(private readonly providerService: ProviderService) {}

  @GrpcMethod('ProviderService', 'FindAll')
  async findAll(data: any) {
    return await this.providerService.findAll(data);
  }

  @GrpcMethod('ProviderService', 'FindOne')
  async findOne(data: { id: string }) {
    return await this.providerService.findOne(data.id);
  }

  @GrpcMethod('ProviderService', 'Create')
  async create(data: any) {
    return await this.providerService.create(data);
  }

  @GrpcMethod('ProviderService', 'Update')
  async update(data: any) {
    return await this.providerService.update(data.id, data);
  }

  @GrpcMethod('ProviderService', 'Delete')
  async delete(data: { id: string }) {
    return await this.providerService.delete(data.id);
  }

  @GrpcMethod('ProviderService', 'GetCities')
  async getCities() {
    return await this.providerService.getCities();
  }

  @GrpcMethod('ProviderService', 'StartTurkeyGeneralCrawl')
  async startTurkeyGeneralCrawl() {
    return await this.providerService.startTurkeyGeneralCrawl();
  }
}