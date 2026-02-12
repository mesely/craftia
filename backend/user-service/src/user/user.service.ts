import { Injectable } from '@nestjs/common';
import { RpcException } from '@nestjs/microservices';

@Injectable()
export class UserService {
  // : any[] ekleyerek TypeScript'in "never" hatasını bitiriyoruz
  private users: any[] = [];

  create(data: any) {
    const newUser = {
      id: Math.random().toString(36).substr(2, 9),
      ...data,
      createdAt: new Date().toISOString(),
    };
    this.users.push(newUser);
    return newUser;
  }

  findOne(id: string) {
    const user = this.users.find((u) => u.id === id);
    if (!user) {
      throw new RpcException('Kullanıcı bulunamadı');
    }
    return user;
  }

  update(id: string, data: any) {
    const index = this.users.findIndex((u) => u.id === id);
    if (index === -1) {
      throw new RpcException('Güncellenecek kullanıcı bulunamadı');
    }
    // Mevcut kullanıcıyı yeni gelen verilerle harmanlıyoruz
    this.users[index] = { ...this.users[index], ...data };
    return this.users[index];
  }

  remove(id: string) {
    const index = this.users.findIndex((u) => u.id === id);
    if (index === -1) {
      throw new RpcException('Silinecek kullanıcı bulunamadı');
    }
    this.users.splice(index, 1);
    return { success: true };
  }
}