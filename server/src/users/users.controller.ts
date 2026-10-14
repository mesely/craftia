import { Controller, Get, NotFoundException, Param } from '@nestjs/common';
import { UsersRepository } from './users.repository';

@Controller('users')
export class UsersController {
  constructor(private readonly users: UsersRepository) {}

  @Get(':id')
  async get(@Param('id') id: string) {
    const user = await this.users.findById(id);
    if (!user) throw new NotFoundException('Kullanıcı bulunamadı.');
    return user;
  }
}
