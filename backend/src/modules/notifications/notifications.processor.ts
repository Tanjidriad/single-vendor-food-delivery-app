import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Logger } from '@nestjs/common';
import { Job } from 'bullmq';
import { NOTIFICATIONS_QUEUE } from '../../common/queues/queue.constants';
import { NotificationsService, PushPayload } from './notifications.service';

export interface SendNotificationJob {
  userId: string;
  title: string;
  body: string;
  data?: PushPayload;
}

@Processor(NOTIFICATIONS_QUEUE)
export class NotificationsProcessor extends WorkerHost {
  private readonly logger = new Logger(NotificationsProcessor.name);

  constructor(private notifications: NotificationsService) {
    super();
  }

  async process(job: Job<SendNotificationJob>): Promise<void> {
    const { userId, title, body, data } = job.data;
    try {
      await this.notifications.sendToUser(userId, title, body, data);
    } catch (err) {
      this.logger.error(
        `Failed to send notification to ${userId}: ${err instanceof Error ? err.message : err}`,
      );
      throw err;
    }
  }
}
