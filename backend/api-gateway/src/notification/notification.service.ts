import { Injectable, OnModuleInit, Inject } from '@nestjs/common';
import { ClientGrpc } from '@nestjs/microservices';

@Injectable()
export class NotificationGatewayService implements OnModuleInit {
  private notificationService: any;

  constructor(@Inject('NOTIFICATION_PACKAGE') private client: ClientGrpc) {}

  onModuleInit() {
    this.notificationService = this.client.getService<any>('NotificationService');
  }

  sendEmail(data: any) {
    return this.notificationService.sendEmail(data);
  }

  sendPush(data: any) {
    return this.notificationService.sendPush(data);
  }

  getHistory(userId: string) {
    return this.notificationService.getHistory({ userId });
  }

  delete(id: string) {
    return this.notificationService.deleteNotification({ id });
  }
}