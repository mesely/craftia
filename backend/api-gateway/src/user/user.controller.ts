import { Controller, Get, Post, Body, Param, Patch, Delete } from '@nestjs/common';
import { UserGatewayService } from './user.service';

@Controller('api/v1/users')
export class UserGatewayController {
  constructor(private readonly userService: UserGatewayService) {}

  @Post()
  create(@Body() data: any) {
    return this.userService.createUser(data);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.userService.getUser(id);
  }

  @Patch(':id')
  update(@Param('id') id: string, @Body() data: any) {
    return this.userService.updateUser(id, data);
  }

  @Delete(':id')
  delete(@Param('id') id: string) {
    return this.userService.deleteUser(id);
  }
}