import { Controller } from '@nestjs/common';
import { GrpcMethod } from '@nestjs/microservices';
import { UserService } from './user.service';
import { CreateUserDto, UpdateUserDto } from './user.interface';

@Controller()
export class UserController {
  constructor(private readonly userService: UserService) {}

  @GrpcMethod('UserService', 'CreateUser')
  async createUser(data: CreateUserDto) {
    return this.userService.create(data);
  }

  @GrpcMethod('UserService', 'FindAll')
  async findAll() {
    const users = await this.userService.findAll();
    return { users };
  }

  @GrpcMethod('UserService', 'FindOne')
  async findOne(data: { id: string }) {
    return this.userService.findOne(data.id);
  }

  @GrpcMethod('UserService', 'UpdateUser')
  async updateUser(data: UpdateUserDto) {
    return this.userService.update(data.id, data);
  }

  @GrpcMethod('UserService', 'DeleteUser')
  async deleteUser(data: { id: string }) {
    return this.userService.delete(data.id);
  }
}