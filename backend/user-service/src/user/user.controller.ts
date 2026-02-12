import { Controller } from '@nestjs/common';
import { GrpcMethod } from '@nestjs/microservices';
import { UserService } from './user.service';


@Controller()
export class UserController {
  constructor(private readonly userService: UserService) {}

  @GrpcMethod('UserService', 'CreateUser')
  createUser(data: any) { return this.userService.create(data); }

  @GrpcMethod('UserService', 'GetUser') // GET hatasının çözümü
  getUser(data: { id: string }) { return this.userService.findOne(data.id); }

  @GrpcMethod('UserService', 'UpdateUser') // PUT hatasının çözümü
  updateUser(data: any) { return this.userService.update(data.id, data); }

  @GrpcMethod('UserService', 'DeleteUser') // DELETE hatasının çözümü
  deleteUser(data: { id: string }) { return this.userService.remove(data.id); }
}