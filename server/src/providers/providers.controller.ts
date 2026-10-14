import { Body, Controller, Get, Param, Post, Query } from '@nestjs/common';
import { CreateProviderDto, ListProvidersDto, LocationQueryDto } from './providers.dto';
import { ProvidersService } from './providers.service';

@Controller('providers')
export class ProvidersController {
  constructor(private readonly providers: ProvidersService) {}

  @Get()
  list(@Query() query: ListProvidersDto) {
    return this.providers.list(query);
  }

  @Get(':id')
  get(@Param('id') id: string, @Query() loc: LocationQueryDto) {
    return this.providers.get(id, loc.userLat, loc.userLng);
  }

  @Post()
  create(@Body() body: CreateProviderDto) {
    return this.providers.create(body);
  }
}
