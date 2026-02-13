import { Injectable, OnModuleInit, Inject } from '@nestjs/common';
import { ClientGrpc } from '@nestjs/microservices';

@Injectable()
export class UserGatewayService implements OnModuleInit {
  private userService: any;

  constructor(@Inject('USER_PACKAGE') private client: ClientGrpc) {}

  onModuleInit() {
    this.userService = this.client.getService<any>('UserService');
  }

  createUser(data: any) {
    return this.userService.createUser(data);
  }

  getUser(id: string) {
    return this.userService.getUser({ id });
  }

  updateUser(id: string, data: any) {
    return this.userService.updateUser({ id, ...data });
  }

  deleteUser(id: string) {
    return this.userService.deleteUser({ id });
  }
}