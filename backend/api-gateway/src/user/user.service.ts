import { Injectable, OnModuleInit, Inject } from '@nestjs/common';
import { ClientGrpc } from '@nestjs/microservices';
import { Observable } from 'rxjs';

interface UserGrpcService {
  createUser(data: any): Observable<any>;
  getUser(data: { id: string }): Observable<any>;
  updateUser(data: any): Observable<any>;
  deleteUser(data: { id: string }): Observable<any>;
}

@Injectable()
export class UserService implements OnModuleInit {
  private userServiceClient: UserGrpcService;

  constructor(@Inject('USER_PACKAGE') private client: ClientGrpc) {}

  onModuleInit() {
    this.userServiceClient = this.client.getService<UserGrpcService>('UserService');
  }

  createUser(data: any) {
    return this.userServiceClient.createUser(data);
  }

  getUser(data: { id: string }) {
    return this.userServiceClient.getUser(data);
  }

  updateUser(data: any) {
    return this.userServiceClient.updateUser(data);
  }

  deleteUser(data: { id: string }) {
    return this.userServiceClient.deleteUser(data);
  }
}