import { Body, Controller, Get, Param, Patch, Post, Query } from '@nestjs/common';
import { CreateServiceRequestDto, UpdateStatusDto } from './orders.dto';
import { OrdersService } from './orders.service';

@Controller('service-requests')
export class OrdersController {
  constructor(private readonly orders: OrdersService) {}

  @Post()
  create(@Body() body: CreateServiceRequestDto) {
    return this.orders.create(body);
  }

  @Get()
  list(@Query('userId') userId?: string) {
    return this.orders.listByUser(userId);
  }

  @Patch(':id/status')
  updateStatus(@Param('id') id: string, @Body() _body: UpdateStatusDto) {
    return this.orders.cancel(id);
  }
}
