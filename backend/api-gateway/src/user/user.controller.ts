import { Controller, Get, Post, Body, Param, Put, Delete } from '@nestjs/common';
import { UserService } from './user.service';

@Controller('users')
export class UserController {
  constructor(private readonly userService: UserService) {}

  @Post()
  createUser(@Body() data: any) {
    return this.userService.createUser(data);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.userService.getUser({ id });
  }

  @Put(':id')
  updateUser(@Param('id') id: string, @Body() data: any) {
    return this.userService.updateUser({ id, ...data });
  }

  @Delete(':id')
  deleteUser(@Param('id') id: string) {
    return this.userService.deleteUser({ id });
  }
}