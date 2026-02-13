import { Controller, Get, Post, Body, Param, Patch, Query } from '@nestjs/common';
import { OrderGatewayService } from './order.service';

@Controller('api/v1/orders')
export class OrderGatewayController {
  constructor(private readonly orderService: OrderGatewayService) {}

  @Post()
  create(@Body() data: any) {
    return this.orderService.create(data);
  }

  @Get('nearby')
  findNearby(
    @Query('lon') lon: number,
    @Query('lat') lat: number,
    @Query('radius') radius: number,
  ) {
    return this.orderService.findNearby(Number(lon), Number(lat), Number(radius));
  }

  @Get('user/:userId')
  findByUser(@Param('userId') userId: string) {
    return this.orderService.findByUser(userId);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.orderService.findOne(id);
  }

  @Patch(':id/status')
  updateStatus(@Param('id') id: string, @Body('status') status: string) {
    return this.orderService.updateStatus(id, status);
  }
}