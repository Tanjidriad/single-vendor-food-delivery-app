import './instrument';
import { ValidationPipe } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { NestFactory } from '@nestjs/core';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import helmet from 'helmet';
import { AppModule } from './app.module';
import { SocketIoCorsAdapter } from './common/adapters/socket-io-cors.adapter';
import { GlobalExceptionFilter } from './common/filters/http-exception.filter';
import { DevService } from './modules/dev/dev.service';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.enableShutdownHooks();
  const config = app.get(ConfigService);

  app.use(helmet());
  app.useWebSocketAdapter(new SocketIoCorsAdapter(app));

  const apiPrefix = config.get<string>('apiPrefix') ?? 'api/v1';
  app.setGlobalPrefix(apiPrefix);

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );
  app.useGlobalFilters(new GlobalExceptionFilter());

  const nodeEnv = config.get<string>('nodeEnv') ?? 'production';
  const isProd = nodeEnv === 'production';

  const corsOrigins = config.get<string[]>('corsOrigins') ?? ['*'];
  const allowAllOrigins = corsOrigins.includes('*');
  if (isProd && allowAllOrigins) {
    // Defense in depth: env validation already blocks this, but never let a
    // wildcard + credentials combination through in production.
    throw new Error(
      'CORS_ORIGINS must be an explicit allowlist in production (wildcard "*" is not allowed).',
    );
  }
  app.enableCors({
    origin: allowAllOrigins ? true : corsOrigins,
    credentials: true,
  });

  // Swagger exposes the full API surface — only mount it outside production.
  if (!isProd) {
    const swaggerConfig = new DocumentBuilder()
      .setTitle('Food Delivery API')
      .setDescription('Single-restaurant food delivery platform')
      .setVersion('0.1.0')
      .addBearerAuth()
      .build();
    const document = SwaggerModule.createDocument(app, swaggerConfig);
    SwaggerModule.setup('api/docs', app, document);
  }

  const port = config.get<number>('port') ?? 3000;
  const host = config.get<string>('host') ?? '0.0.0.0';
  await app.listen(port, host);

  console.log(`API listening on ${host}:${port}/${apiPrefix}`);

  // Dev-only startup helpers (LAN URL discovery, Flutter asset sync). Skipped in
  // production where they're meaningless and only add noise / filesystem writes.
  if (!isProd) {
    const devService = app.get(DevService);
    const urls = devService.getStartupUrls(port, apiPrefix);
    const assetPath = devService.syncFlutterDevHostAsset();

    console.log(`  Local:            ${urls.local}`);
    console.log(`  Android emulator: ${urls.androidEmulator}`);
    if (urls.physicalDevice) {
      console.log(`  Physical device:  ${urls.physicalDevice}`);
    }
    if (urls.allLan.length > 1) {
      console.log(`  Other LAN IPs:    ${urls.allLan.join(', ')}`);
    }
    console.log(`  Swagger:          ${urls.swagger}`);
    console.log(`  Dev config:       http://localhost:${port}/${apiPrefix}/dev/client-config`);
    if (assetPath) {
      console.log(`  Flutter asset:    ${assetPath}`);
      console.log('  → Re-run the Flutter app on a physical device after starting the API.');
    }
  }
}
bootstrap();
