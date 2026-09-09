import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Cron, CronExpression } from '@nestjs/schedule';
import { acquireCronLock } from '../../common/utils/redis-lock.util';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class RiderLocationCleanupService {
  private readonly logger = new Logger(RiderLocationCleanupService.name);

  constructor(
    private prisma: PrismaService,
    private config: ConfigService,
  ) {}

  @Cron(CronExpression.EVERY_DAY_AT_3AM)
  async cleanup() {
    if (!(await acquireCronLock(this.config, 'rider-location-cleanup', 3600))) return;

    const cutoff = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
    const result = await this.prisma.riderLocation.deleteMany({
      where: { recordedAt: { lt: cutoff } },
    });

    if (result.count > 0) {
      this.logger.log(`Deleted ${result.count} rider location rows older than 7 days`);
    }
  }
}
