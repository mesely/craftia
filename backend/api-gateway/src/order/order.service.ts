import { Injectable, OnModuleInit, Inject } from '@nestjs/common';
import { ClientGrpc } from '@nestjs/microservices';

@Injectable()
export class OrderGatewayService implements OnModuleInit {
  private orderService: any;

  constructor(@Inject('ORDER_PACKAGE') private client: ClientGrpc) {}

  onModuleInit() {
    this.orderService = this.client.getService<any>('OrderService');
  }

  create(data: any) {
    return this.orderService.createOrder(data);
  }

  findOne(id: string) {
    return this.orderService.getOrder({ id });
  }

  findByUser(userId: string) {
    return this.orderService.getUserOrders({ userId });
  }

  updateStatus(id: string, status: string) {
    return this.orderService.updateOrderStatus({ id, status });
  }

  findNearby(lon: number, lat: number, radius: number) {
    return this.orderService.findNearby({ longitude: lon, latitude: lat, radius });
  }
}