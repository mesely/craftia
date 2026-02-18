import { Controller, Get, Query, Param, Post, Body, Delete } from '@nestjs/common';
import { ProviderGatewayService } from './provider.service';
import { Put } from '@nestjs/common';

@Controller('api/v1/providers')
export class ProviderGatewayController {
  constructor(private readonly providerService: ProviderGatewayService) {}

  // Frontend'den gelen Usta Kayıt Formunu karşılar
  @Post()
  async create(@Body() body: any) {
    return await this.providerService.create(body);
  }

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
  @Put(':id')
  async update(@Param('id') id: string, @Body() body: any) {
    return await this.providerService.update({ id, ...body }); // Body'nin içine id'yi de ekleyip microservice'e atıyoruz
  }
  @Delete(':id')
async delete(@Param('id') id: string) {
  return await this.providerService.delete(id); // microservice'deki delete'i tetikler
}
}