import { Injectable } from '@nestjs/common';
import { NewNotification, NotificationsRepository } from './notifications.repository';

/** Records notifications. Actual push/e-mail delivery is intentionally out of scope. */
@Injectable()
export class NotificationsService {
  constructor(private readonly repo: NotificationsRepository) {}

  record(data: NewNotification) {
    return this.repo.add(data);
  }

  listFor(recipient: string) {
    return this.repo.listFor(recipient);
  }
}
