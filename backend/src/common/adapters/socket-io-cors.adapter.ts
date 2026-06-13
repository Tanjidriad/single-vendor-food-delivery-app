import { INestApplicationContext } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { IoAdapter } from '@nestjs/platform-socket.io';
import { ServerOptions } from 'socket.io';
import { corsOriginSetting } from '../../config/cors.util';

/**
 * Applies the same CORS allowlist as HTTP (ConfigModule) to Socket.IO,
 * instead of reading raw process.env at gateway import time.
 */
export class SocketIoCorsAdapter extends IoAdapter {
  constructor(private readonly app: INestApplicationContext) {
    super(app);
  }

  createIOServer(port: number, options?: ServerOptions) {
    const config = this.app.get(ConfigService);
    const nodeEnv = config.get<string>('nodeEnv') ?? 'production';
    const corsOrigins = config.get<string[]>('corsOrigins') ?? ['*'];

    if (nodeEnv === 'production' && corsOrigins.includes('*')) {
      throw new Error(
        'CORS_ORIGINS must be an explicit allowlist in production (wildcard "*" is not allowed).',
      );
    }

    return super.createIOServer(port, {
      ...options,
      cors: {
        origin: corsOriginSetting(corsOrigins),
        credentials: true,
      },
    });
  }
}
