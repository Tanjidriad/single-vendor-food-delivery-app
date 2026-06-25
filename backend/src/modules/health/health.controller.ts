import {
  Controller,
  Get,
  HttpStatus,
  OnModuleDestroy,
  Res,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ApiTags } from '@nestjs/swagger';
import Redis from 'ioredis';
import * as express from 'express';
import { Public } from '../../common/decorators/public.decorator';
import { PrismaService } from '../../prisma/prisma.service';

@ApiTags('health')
@Controller('health')
export class HealthController implements OnModuleDestroy {
  private redis: Redis | null = null;

  constructor(
    private prisma: PrismaService,
    private config: ConfigService,
  ) {}

  /**
   * Liveness: is the process up and serving? Must NOT depend on external
   * services — a failing DB/Redis should not cause the orchestrator to kill and
   * restart the container (a restart won't fix a downstream outage).
   */
  @Public()
  @Get('live')
  live(@Res() res: express.Response) {
    res.status(HttpStatus.OK).json({
      status: 'ok',
      service: 'food-delivery-api',
      timestamp: new Date().toISOString(),
    });
  }

  /**
   * Readiness: can this instance actually serve traffic? Checks the
   * dependencies a request needs (Postgres + Redis). Returns 503 when a
   * dependency is down so the load balancer routes around this instance.
   */
  @Public()
  @Get('ready')
  async ready(@Res() res: express.Response) {
    const [database, redis] = await Promise.all([
      this.checkDatabase(),
      this.checkRedis(),
    ]);

    const healthy = database === 'ok' && redis !== 'unreachable';
    res.status(healthy ? HttpStatus.OK : HttpStatus.SERVICE_UNAVAILABLE).json({
      status: healthy ? 'ok' : 'degraded',
      service: 'food-delivery-api',
      timestamp: new Date().toISOString(),
      database,
      redis,
    });
  }

  /** Legacy combined check (DB) kept for the Docker HEALTHCHECK and clients. */
  @Public()
  @Get()
  async check(@Res() res: express.Response) {
    const database = await this.checkDatabase();
    const healthy = database === 'ok';
    res.status(healthy ? HttpStatus.OK : HttpStatus.SERVICE_UNAVAILABLE).json({
      status: healthy ? 'ok' : 'degraded',
      service: 'food-delivery-api',
      timestamp: new Date().toISOString(),
      database,
    });
  }

  private async checkDatabase(): Promise<'ok' | 'unreachable'> {
    try {
      await this.prisma.$queryRaw`SELECT 1`;
      return 'ok';
    } catch {
      return 'unreachable';
    }
  }

  private async checkRedis(): Promise<'ok' | 'unreachable' | 'not_configured'> {
    const url = this.config.get<string>('redisUrl');
    if (!url) return 'not_configured';
    try {
      const client = this.getRedis(url);
      const pong = await client.ping();
      return pong === 'PONG' ? 'ok' : 'unreachable';
    } catch {
      return 'unreachable';
    }
  }

  private getRedis(url: string): Redis {
    if (!this.redis) {
      this.redis = new Redis(url, {
        lazyConnect: true,
        enableOfflineQueue: false,
        maxRetriesPerRequest: 1,
        connectTimeout: 2000,
        // Don't spam logs / crash the process if Redis is down; readiness
        // reports the failure instead.
        retryStrategy: () => null,
      });
      this.redis.on('error', () => {
        /* swallowed — checkRedis surfaces the failure */
      });
    }
    return this.redis;
  }

  async onModuleDestroy() {
    if (this.redis) {
      await this.redis.quit().catch(() => undefined);
      this.redis = null;
    }
  }
}
