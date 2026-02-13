import { Controller, Get, Post, Body, Param, Delete } from '@nestjs/common';
import { NotificationGatewayService } from './notification.service';

@Controller('api/v1/notifications')
export class NotificationGatewayController {
  constructor(private readonly notificationService: NotificationGatewayService) {}

  @Post('email')
  sendEmail(@Body() data: any) {
    return this.notificationService.sendEmail(data);
  }

  @Post('push')
  sendPush(@Body() data: any) {
    return this.notificationService.sendPush(data);
  }

  @Get('history/:userId')
  getHistory(@Param('userId') userId: string) {
    return this.notificationService.getHistory(userId);
  }

  @Delete(':id')
  delete(@Param('id') id: string) {
    return this.notificationService.delete(id);
  }
}