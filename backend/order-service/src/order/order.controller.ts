import { Controller } from '@nestjs/common';
import { GrpcMethod } from '@nestjs/microservices';
import { OrderService } from './order.service';

@Controller()
export class OrderController {
  constructor(private readonly orderService: OrderService) {}

  @GrpcMethod('OrderService', 'CreateOrder')
  createOrder(data: any) {
    return this.orderService.create(data);
  }

  @GrpcMethod('OrderService', 'GetOrder')
  getOrder(data: { id: string }) {
    return this.orderService.findOne(data.id);
  }

  @GrpcMethod('OrderService', 'GetUserOrders')
  async getUserOrders(data: { userId: string }) {
    const orders = await this.orderService.findByUser(data.userId);
    return { orders };
  }

  @GrpcMethod('OrderService', 'UpdateOrderStatus')
  updateStatus(data: { id: string; status: string }) {
    return this.orderService.updateStatus(data.id, data.status);
  }

  @GrpcMethod('OrderService', 'FindNearby')
  async findNearby(data: { longitude: number; latitude: number; radius: number }) {
    const orders = await this.orderService.findNearby(data.longitude, data.latitude, data.radius);
    return { orders };
  }
}