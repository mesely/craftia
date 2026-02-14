import { Controller, Get, Post, Body, Param, Patch, Delete, Query } from '@nestjs/common';
import { ProviderGatewayService } from './provider.service';

@Controller('api/v1/providers')
export class ProviderGatewayController {
  constructor(private readonly providerService: ProviderGatewayService) {}

  @Post()
  create(@Body() data: any) {
    return this.providerService.create(data);
  }

  /**
   * ✅ GÜNCELLENDİ: Tüm filtreler ve konum verileri yakalanıyor.
   * Frontend (UstaList.tsx) üzerinden gelen url parametrelerini gRPC servisine paslar.
   */
  @Get()
  findAll(
    @Query('page') page?: number,
    @Query('limit') limit?: number,
    @Query('mainType') mainType?: string,
    @Query('subType') subType?: string,
    @Query('city') city?: string,
    @Query('sort') sort?: string, // Frontend 'sort' olarak yolluyor
    @Query('userLat') userLat?: number,
    @Query('userLng') userLng?: number,
  ) {
    return this.providerService.findAll({
      page: Number(page) || 1,
      limit: Number(limit) || 10,
      mainType,
      subType,
      city,
      sort,
      userLat: userLat ? Number(userLat) : undefined,
      userLng: userLng ? Number(userLng) : undefined
    });
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