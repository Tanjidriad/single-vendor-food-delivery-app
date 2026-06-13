import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as admin from 'firebase-admin';

@Injectable()
export class FcmService implements OnModuleInit {
  private readonly logger = new Logger(FcmService.name);
  private enabled = false;

  constructor(private config: ConfigService) {}

  onModuleInit() {
    const projectId = this.config.get<string>('fcm.projectId');
    const clientEmail = this.config.get<string>('fcm.clientEmail');
    const privateKey = this.config.get<string>('fcm.privateKey');
    if (projectId && clientEmail && privateKey) {
      try {
        if (!admin.apps.length) {
          admin.initializeApp({
            credential: admin.credential.cert({
              projectId,
              clientEmail,
              privateKey,
            }),
          });
        }
        this.enabled = true;
        this.logger.log('Firebase Admin initialized for FCM');
      } catch (err) {
        this.logger.warn(`FCM init failed: ${err}`);
      }
      return;
    }

    const nodeEnv = this.config.get<string>('nodeEnv') ?? 'production';
    if (nodeEnv === 'production') {
      this.logger.warn(
        'FCM not configured (FCM_PROJECT_ID, FCM_CLIENT_EMAIL, FCM_PRIVATE_KEY). Push notifications are disabled.',
      );
    }
  }

  async send(token: string, title: string, body: string, data?: Record<string, string>) {
    if (!this.enabled) return { success: false, reason: 'FCM not configured' };
    const messageId = await admin.messaging().send({
      token,
      notification: { title, body },
      data,
    });
    return { success: true, messageId };
  }

  /** Send to multiple tokens at once — avoids N+1 individual send() calls */
  async sendMulticast(
    tokens: string[],
    title: string,
    body: string,
    data?: Record<string, string>,
  ): Promise<{ successes: number; failures: number; responses: { token: string; success: boolean; error?: string }[] }> {
    if (!this.enabled) {
      return {
        successes: 0,
        failures: tokens.length,
        responses: tokens.map((token) => ({ token, success: false, error: 'FCM not configured' })),
      };
    }
    if (tokens.length === 0) {
      return { successes: 0, failures: 0, responses: [] };
    }

    const message: admin.messaging.MulticastMessage = {
      tokens,
      notification: { title, body },
      data,
    };

    const result = await admin.messaging().sendEachForMulticast(message);
    const responses = result.responses.map((r, i) => ({
      token: tokens[i],
      success: r.success,
      error: r.error?.message,
    }));

    return {
      successes: result.successCount,
      failures: result.failureCount,
      responses,
    };
  }
}
