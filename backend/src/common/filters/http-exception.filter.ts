import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import * as Sentry from '@sentry/nestjs';
import { Request, Response } from 'express';

@Catch()
export class GlobalExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger(GlobalExceptionFilter.name);

  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();

    const status =
      exception instanceof HttpException
        ? exception.getStatus()
        : HttpStatus.INTERNAL_SERVER_ERROR;

    const message =
      exception instanceof HttpException
        ? exception.getResponse()
        : 'Internal server error';

    const requestId = (request as Request & { requestId?: string }).requestId;

    if (status >= 500) {
      this.logger.error(
        `[${requestId ?? 'no-id'}] ${request.method} ${request.url}`,
        exception instanceof Error ? exception.stack : String(exception),
      );
      if (process.env.SENTRY_DSN?.trim()) {
        Sentry.captureException(exception);
      }
    }

    const body =
      typeof message === 'string'
        ? { statusCode: status, message, path: request.url }
        : { ...(message as object), path: request.url };

    response.status(status).json({
      success: false,
      ...body,
      requestId,
      timestamp: new Date().toISOString(),
    });
  }
}
