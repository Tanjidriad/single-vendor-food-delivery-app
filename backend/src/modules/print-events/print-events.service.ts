import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { RealtimeService } from '../../gateways/realtime.service';

@Injectable()
export class PrintEventsService {
  constructor(
    private prisma: PrismaService,
    private realtime: RealtimeService,
  ) {}

  async logAndEmit(params: {
    orderId: string;
    restaurantId: string;
    printType: 'KITCHEN_TICKET' | 'CUSTOMER_RECEIPT';
    status: 'REQUESTED' | 'SUCCESS' | 'FAILED';
    deviceInfo?: string;
  }) {
    const log = await this.prisma.printLog.create({
      data: params,
    });
    this.realtime.emitToRoom(
      `restaurant:${params.restaurantId}`,
      'print:requested',
      { ...params, printLogId: log.id },
    );
    return log;
  }

  listByOrder(orderId: string) {
    return this.prisma.printLog.findMany({
      where: { orderId },
      orderBy: { createdAt: 'desc' },
    });
  }
}
