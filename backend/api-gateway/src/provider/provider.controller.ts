import { Controller, Get, Post, Body, Param, Put, Delete } from '@nestjs/common';
import { ProviderService } from './provider.service';

@Controller('providers')
export class ProviderController {
  constructor(private readonly providerService: ProviderService) {}

  @Post()
  createProvider(@Body() data: any) {
    return this.providerService.createProvider(data);
  }

  @Get()
  findAll() {
    return this.providerService.findAll();
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.providerService.findOne(id);
  }

  @Put(':id')
  updateProvider(@Param('id') id: string, @Body() data: any) {
    return this.providerService.updateProvider(id, data);
  }

  @Delete(':id')
  deleteProvider(@Param('id') id: string) {
    return this.providerService.deleteProvider(id);
  }
}