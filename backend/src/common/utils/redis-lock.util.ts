import { ConfigService } from '@nestjs/config';
import Redis from 'ioredis';

let redisClient: Redis | null = null;

function getRedis(config: ConfigService): Redis | null {
  if (redisClient) return redisClient;
  const url = config.get<string>('redisUrl');
  if (!url) return null;
  redisClient = new Redis(url);
  return redisClient;
}

/**
 * Acquire a short-lived distributed lock so only one instance runs a cron job.
 * Returns true if the lock was acquired.
 */
export async function acquireCronLock(
  config: ConfigService,
  key: string,
  ttlSeconds: number,
): Promise<boolean> {
  const redis = getRedis(config);
  if (!redis) return true;
  const result = await redis.set(`cron-lock:${key}`, '1', 'EX', ttlSeconds, 'NX');
  return result === 'OK';
}
