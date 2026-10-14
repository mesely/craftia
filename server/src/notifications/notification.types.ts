export interface NotificationEntity {
  id: string;
  type: 'EMAIL' | 'PUSH';
  recipient: string;
  title: string;
  body: string;
  sentAt: string;
}
