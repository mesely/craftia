import { Controller, Get, Query, Param, Post } from '@nestjs/common';
import { ProviderGatewayService } from './provider.service';

@Controller('api/v1/providers')
export class ProviderGatewayController {
  constructor(private readonly providerService: ProviderGatewayService) {}

  @Get()
  async findAll(@Query() query: any) {
    return await this.providerService.findAll(query);
  }

  @Get('cities')
  async getCities() {
    return await this.providerService.getCities();
  }

  @Get(':id')
  async findOne(@Param('id') id: string) {
    return await this.providerService.findOne(id);
  }

  @Post('crawl')
  async startCrawl() {
    return await this.providerService.startTurkeyGeneralCrawl();
  }
}