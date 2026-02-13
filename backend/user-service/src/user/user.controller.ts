import { Controller } from '@nestjs/common';
import { GrpcMethod } from '@nestjs/microservices';
import { UserService } from './user.service';

@Controller()
export class UserController {
  constructor(private readonly userService: UserService) {}

  @GrpcMethod('UserService', 'CreateUser')
  createUser(data: any) {
    return this.userService.createUser(data);
  }

  @GrpcMethod('UserService', 'GetUser')
  getUser(data: { id: string }) {
    return this.userService.getUser(data.id);
  }

  @GrpcMethod('UserService', 'UpdateUser')
  updateUser(data: any) {
    return this.userService.updateUser(data);
  }

  @GrpcMethod('UserService', 'DeleteUser')
  deleteUser(data: { id: string }) {
    return this.userService.deleteUser(data.id);
  }
}