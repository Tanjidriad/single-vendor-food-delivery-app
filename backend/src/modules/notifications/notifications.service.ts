import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { DevicesService } from '../devices/devices.service';
import { FcmService } from './fcm.service';

export interface PushPayload {
  type: string;
  orderId?: string;
  assignmentId?: string;
  pickupLat?: string;
  pickupLng?: string;
  dropLat?: string;
  dropLng?: string;
  expiresAt?: string;
  [key: string]: string | undefined;
}

@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);

  constructor(
    private prisma: PrismaService,
    private devicesService: DevicesService,
    private fcm: FcmService,
  ) {}

  async sendToUser(
    userId: string,
    title: string,
    body: string,
    data?: PushPayload,
  ) {
    await this.prisma.notification.create({
      data: { userId, title, body, data: data ?? {} },
    });

    const devices = await this.devicesService.getActiveTokens(userId);
    if (devices.length === 0) return;

    const stringData: Record<string, string> = {};
    if (data) {
      for (const [k, v] of Object.entries(data)) {
        if (v !== undefined) stringData[k] = String(v);
      }
    }

    const tokens = devices.map((d) => d.token);
    const result = await this.fcm.sendMulticast(tokens, title, body, stringData);

    // Batch-insert notification logs
    const logEntries = result.responses.map((r) => ({
      userId,
      channel: 'FCM' as const,
      eventType: data?.type ?? 'generic',
      payload: { title, body, data, result: r } as object,
      status: r.success ? 'SENT' : 'FAILED',
      error: r.error ?? null,
    }));

    if (logEntries.length > 0) {
      await this.prisma.notificationLog.createMany({ data: logEntries });
    }

    // Deactivate invalid tokens
    for (const r of result.responses) {
      if (!r.success && r.error?.includes('registration-token')) {
        const device = devices.find((d) => d.token === r.token);
        if (device) {
          await this.devicesService.deactivate(userId, device.deviceId);
        }
      }
    }
  }
}
