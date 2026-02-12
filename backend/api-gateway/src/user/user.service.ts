import { Injectable, OnModuleInit, Inject } from '@nestjs/common';
import { ClientGrpc } from '@nestjs/microservices';
import { map } from 'rxjs/operators';

@Injectable()
export class UserService implements OnModuleInit {
  private userServiceClient: any;

  constructor(@Inject('USER_PACKAGE') private client: ClientGrpc) {}

  onModuleInit() {
    // Proto içindeki UserService ismiyle eşleşmeli
    this.userServiceClient = this.client.getService<any>('UserService');
  }

  createUser(data: any) {
    return this.userServiceClient.createUser(data);
  }

  findAll() {
    return this.userServiceClient.findAll({});
  }

  findOne(id: string) {
    return this.userServiceClient.findOne({ id });
  }

  updateUser(id: string, data: any) {
    return this.userServiceClient.updateUser({ id, ...data });
  }

  deleteUser(id: string) {
    return this.userServiceClient.deleteUser({ id });
  }
}