import { Body, Controller, Delete, Get, Param, Patch, Post, Query } from '@nestjs/common';
import { CreateProviderDto, ListProvidersDto, LocationQueryDto, ProviderPhotoDto, UpdateProviderDto } from './providers.dto';
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

  @Patch(':id')
  update(@Param('id') id: string, @Body() body: UpdateProviderDto) {
    return this.providers.update(id, body);
  }

  @Post(':id/photos')
  addPhoto(@Param('id') id: string, @Body() body: ProviderPhotoDto) {
    return this.providers.addPhoto(id, body);
  }

  @Post(':id/profile-photo')
  setProfilePhoto(@Param('id') id: string, @Body() body: ProviderPhotoDto) {
    return this.providers.setProfilePhoto(id, body);
  }

  @Delete(':id/photos')
  removePhoto(@Param('id') id: string, @Query('actorId') actorId = '', @Query('path') path = '') {
    return this.providers.removePhoto(id, actorId, path);
  }
}
