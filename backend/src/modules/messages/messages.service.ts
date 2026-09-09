import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { UserRole } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { RealtimeService } from '../../gateways/realtime.service';
import { JwtPayload } from '../auth/interfaces/jwt-payload.interface';

const STAFF_ROLES: UserRole[] = [
  UserRole.OWNER,
  UserRole.MANAGER,
  UserRole.CASHIER,
  UserRole.ADMIN,
];

@Injectable()
export class MessagesService {
  constructor(
    private prisma: PrismaService,
    private realtime: RealtimeService,
  ) {}

  /// Loads the order with the fields needed to authorize chat access, or throws.
  private async loadOrderForChat(orderId: string) {
    const order = await this.prisma.order.findUnique({
      where: { id: orderId },
      select: {
        id: true,
        customerId: true,
        restaurantId: true,
        assignment: {
          select: { riderId: true, rider: { select: { userId: true } } },
        },
      },
    });
    if (!order) throw new NotFoundException('Order not found');
    return order;
  }

  /// Only the order's customer, its assigned rider, or restaurant staff may
  /// read or post messages on an order's thread.
  private assertParticipant(
    user: JwtPayload,
    order: Awaited<ReturnType<MessagesService['loadOrderForChat']>>,
  ) {
    const isCustomer =
      user.role === UserRole.CUSTOMER && user.sub === order.customerId;
    const isAssignedRider =
      user.role === UserRole.RIDER &&
      !!user.riderProfileId &&
      user.riderProfileId === order.assignment?.riderId;
    const isStaff =
      STAFF_ROLES.includes(user.role) &&
      (user.role === UserRole.ADMIN ||
        user.restaurantId === order.restaurantId);

    if (!isCustomer && !isAssignedRider && !isStaff) {
      throw new ForbiddenException('Not a participant of this order');
    }
  }

  async list(user: JwtPayload, orderId: string) {
    const order = await this.loadOrderForChat(orderId);
    this.assertParticipant(user, order);

    return this.prisma.message.findMany({
      where: { orderId },
      orderBy: { createdAt: 'asc' },
    });
  }

  async create(user: JwtPayload, orderId: string, body: string) {
    const order = await this.loadOrderForChat(orderId);
    this.assertParticipant(user, order);

    const message = await this.prisma.message.create({
      data: {
        orderId,
        senderId: user.sub,
        senderRole: user.role,
        body: body.trim(),
      },
    });

    // Deliver to the order room (both parties join it when viewing the order)
    // and to each party's personal room as a fallback if they haven't joined.
    this.realtime.emitToRoom(`order:${orderId}`, 'order:message', message);
    this.realtime.emitToRoom(`user:${order.customerId}`, 'order:message', message);
    const riderUserId = order.assignment?.rider?.userId;
    if (riderUserId) {
      this.realtime.emitToRoom(`rider:${riderUserId}`, 'order:message', message);
    }

    return message;
  }
}
