import { BadRequestException, Controller, Get, Query } from '@nestjs/common';
import { NotificationsService } from './notifications.service';

@Controller('notifications')
export class NotificationsController {
  constructor(private readonly notifications: NotificationsService) {}

  @Get()
  list(@Query('userId') userId?: string) {
    if (!userId) throw new BadRequestException('userId gerekli.');
    return this.notifications.listFor(userId);
  }
}
