import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Logger } from '@nestjs/common';
import { Job } from 'bullmq';
import { DISPATCH_QUEUE } from '../../common/queues/queue.constants';
import { DispatchService } from './dispatch.service';
import { RealtimeService } from '../../gateways/realtime.service';

export interface AutoAssignJob {
  userId: string;
  userRole: string;
  restaurantId?: string | null;
  riderProfileId?: string | null;
  orderId: string;
  phase: string;
}

export interface ExpireAssignmentJob {
  assignmentId: string;
}

export interface RiderOnlineRetryJob {
  riderProfileId: string;
}

@Processor(DISPATCH_QUEUE)
export class DispatchProcessor extends WorkerHost {
  private readonly logger = new Logger(DispatchProcessor.name);

  constructor(
    private dispatch: DispatchService,
    private realtime: RealtimeService,
  ) {
    super();
  }

  async process(job: Job): Promise<void> {
    switch (job.name) {
      case 'auto-assign':
        return this.handleAutoAssign(job as Job<AutoAssignJob>);
      case 'expire-assignment':
        return this.handleExpireAssignment(job as Job<ExpireAssignmentJob>);
      case 'rider-online-retry':
        return this.handleRiderOnlineRetry(job as Job<RiderOnlineRetryJob>);
      default:
        this.logger.warn(`Unknown dispatch job: ${job.name}`);
    }
  }

  private async handleAutoAssign(job: Job<AutoAssignJob>): Promise<void> {
    const { userId, userRole, restaurantId, riderProfileId, orderId, phase } = job.data;
    const user = { sub: userId, role: userRole as any, restaurantId, riderProfileId };
    try {
      const assignment = await this.dispatch.autoAssign(user, orderId);
      this.logger.log(`Auto-assigned rider ${assignment.riderId} for order ${orderId}`);
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      this.logger.warn(`Failed to auto-assign order ${orderId} at ${phase}: ${message}`);
      if (restaurantId) {
        this.realtime.emitToRoom(`restaurant:${restaurantId}`, 'order:dispatch.failed', {
          orderId,
          phase,
          reason: message,
        });
      }
      throw err;
    }
  }

  private async handleExpireAssignment(job: Job<ExpireAssignmentJob>): Promise<void> {
    await this.dispatch.expireIfStillPending(job.data.assignmentId);
  }

  private async handleRiderOnlineRetry(job: Job<RiderOnlineRetryJob>): Promise<void> {
    await this.dispatch.retryDispatchWhenRiderGoesOnline(job.data.riderProfileId);
  }
}
