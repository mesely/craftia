import { Controller } from '@nestjs/common';
import { GrpcMethod } from '@nestjs/microservices';
import { NotificationService } from './notification.service';

@Controller()
export class NotificationController {
  constructor(private readonly notificationService: NotificationService) {}

  @GrpcMethod('NotificationService', 'SendEmail')
  sendEmail(data: any) { return this.notificationService.sendEmail(data); }

  @GrpcMethod('NotificationService', 'SendPush')
  sendPush(data: any) { return this.notificationService.sendPush(data); }

  @GrpcMethod('NotificationService', 'GetHistory')
  getHistory(data: { userId: string }) { return this.notificationService.getHistory(data.userId); }

  @GrpcMethod('NotificationService', 'FindOne')
  findOne(data: { id: string }) { return this.notificationService.findOne(data.id); }

  @GrpcMethod('NotificationService', 'UpdateNotification')
  update(data: { id: string; title: string; body: string }) {
    const { id, ...updateData } = data;
    return this.notificationService.update(id, updateData);
  }

  @GrpcMethod('NotificationService', 'DeleteNotification')
  delete(data: { id: string }) { return this.notificationService.delete(data.id); }
}