import { Controller, Get, Post, Body, Param, Patch, Delete, Query } from '@nestjs/common';
import { ProviderGatewayService } from './provider.service';

@Controller('api/v1/providers')
export class ProviderGatewayController {
  constructor(private readonly providerService: ProviderGatewayService) {}

  @Post()
  create(@Body() data: any) {
    return this.providerService.create(data);
  }

  @Get()
  findAll() {
    return this.providerService.findAll();
  }

  @Get('cities')
  getCities() {
    return this.providerService.getCities();
  }

  @Get('districts')
  getDistricts(@Query('city') city: string) {
    return this.providerService.getDistricts(city);
  }

  @Get('categories')
  getCategories() {
    return this.providerService.getCategories();
  }

  @Post('crawl')
  startCrawl() {
    return this.providerService.startCrawl();
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.providerService.findOne(id);
  }

  @Patch(':id')
  update(@Param('id') id: string, @Body() data: any) {
    return this.providerService.update(id, data);
  }

  @Delete(':id')
  delete(@Param('id') id: string) {
    return this.providerService.delete(id);
  }
}