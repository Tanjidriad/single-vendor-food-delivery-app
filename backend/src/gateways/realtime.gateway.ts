import { Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import {
  ConnectedSocket,
  MessageBody,
  OnGatewayConnection,
  OnGatewayDisconnect,
  OnGatewayInit,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import { UserRole } from '../common/enums/user-role.enum';
import { AssignmentStatus } from '@prisma/client';
import { TokenExpiredError } from 'jsonwebtoken';
import { Server, Socket } from 'socket.io';
import { PrismaService } from '../prisma/prisma.service';
import { JwtPayload } from '../modules/auth/interfaces/jwt-payload.interface';
import { RealtimeService } from './realtime.service';

const STAFF_ROLES: UserRole[] = [
  UserRole.OWNER,
  UserRole.MANAGER,
  UserRole.CASHIER,
  UserRole.KITCHEN,
];

// CORS is applied via SocketIoCorsAdapter in main.ts (same allowlist as HTTP).
@WebSocketGateway({
  namespace: '/realtime',
})
export class RealtimeGateway
  implements OnGatewayInit, OnGatewayConnection, OnGatewayDisconnect
{
  @WebSocketServer()
  server: Server;

  private readonly logger = new Logger(RealtimeGateway.name);
  private readonly lastActionAt = new Map<string, number>();

  constructor(
    private jwt: JwtService,
    private config: ConfigService,
    private prisma: PrismaService,
    private realtime: RealtimeService,
  ) {}

  afterInit() {
    this.realtime.setServer(this.server);
    this.logger.log('Realtime gateway initialized');
  }

  async handleConnection(client: Socket) {
    try {
      const token =
        (client.handshake.auth?.token as string) ||
        (client.handshake.headers.authorization?.replace('Bearer ', '') ??
          '');
      if (!token) {
        this.logger.warn(`Client ${client.id} connected without token, disconnecting`);
        client.disconnect();
        return;
      }
      const payload = await this.jwt.verifyAsync<JwtPayload>(token, {
        secret: this.config.getOrThrow<string>('jwt.accessSecret'),
      });
      const user = await this.prisma.user.findUnique({
        where: { id: payload.sub },
        include: { riderProfile: true },
      });
      if (!user || user.status !== 'ACTIVE') {
        this.logger.warn(
          `Client ${client.id} inactive or missing user ${payload.sub}, disconnecting`,
        );
        client.disconnect();
        return;
      }
      const activePayload: JwtPayload = {
        sub: user.id,
        role: user.role as UserRole,
        restaurantId: user.restaurantId,
        branchId: user.branchId,
        riderProfileId: user.riderProfile?.id ?? null,
      };
      client.data.user = activePayload;
      client.join(`user:${activePayload.sub}`);
      this.logger.log(
        `Client ${client.id} authenticated as ${activePayload.sub} (Role: ${activePayload.role})`,
      );

      if (activePayload.restaurantId) {
        client.join(`restaurant:${activePayload.restaurantId}`);
      }
      if (activePayload.role === UserRole.RIDER) {
        client.join(`rider:${activePayload.sub}`);
        this.logger.log(
          `Client ${client.id} joined room rider:${activePayload.sub}`,
        );
      }
    } catch (err) {
      if (err instanceof TokenExpiredError) {
        this.logger.warn(
          `Client ${client.id} JWT expired — rider/kitchen app should refresh token and reconnect`,
        );
      } else {
        this.logger.error(`Client ${client.id} connection error: ${err}`);
      }
      client.disconnect();
    }
  }

  handleDisconnect(@ConnectedSocket() client: Socket) {
    this.logger.debug(`Client disconnected: ${client.id}`);
    for (const key of this.lastActionAt.keys()) {
      if (key.startsWith(`${client.id}:`)) {
        this.lastActionAt.delete(key);
      }
    }
  }

  private allowAction(client: Socket, action: string, minIntervalMs = 400): boolean {
    const key = `${client.id}:${action}`;
    const now = Date.now();
    const last = this.lastActionAt.get(key) ?? 0;
    if (now - last < minIntervalMs) {
      return false;
    }
    this.lastActionAt.set(key, now);
    return true;
  }

  @SubscribeMessage('order:join')
  async handleJoinOrder(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { orderId: string },
  ) {
    const user = client.data.user as JwtPayload | undefined;
    if (!user || !data?.orderId) {
      return { joined: null, error: 'unauthorized' };
    }
    if (!this.allowAction(client, 'order:join', 300)) {
      return { joined: null, error: 'rate_limited' };
    }

    const order = await this.prisma.order.findUnique({
      where: { id: data.orderId },
      select: {
        customerId: true,
        restaurantId: true,
        assignment: { select: { riderId: true } },
      },
    });
    if (!order || !this.canAccessOrder(user, order)) {
      this.logger.warn(
        `Client ${client.id} (${user.sub}) denied order:join for ${data.orderId}`,
      );
      return { joined: null, error: 'forbidden' };
    }

    client.join(`order:${data.orderId}`);
    return { joined: data.orderId };
  }

  /** Whether a user may view/subscribe to an order's realtime feed. */
  private canAccessOrder(
    user: JwtPayload,
    order: {
      customerId: string;
      restaurantId: string;
      assignment?: { riderId: string } | null;
    },
  ): boolean {
    if (user.role === UserRole.CUSTOMER) {
      return order.customerId === user.sub;
    }
    if (STAFF_ROLES.includes(user.role)) {
      return !!user.restaurantId && user.restaurantId === order.restaurantId;
    }
    if (user.role === UserRole.RIDER) {
      return (
        !!user.riderProfileId &&
        order.assignment?.riderId === user.riderProfileId
      );
    }
    return false;
  }

  @SubscribeMessage('rider:location')
  async handleRiderLocation(
    @ConnectedSocket() client: Socket,
    @MessageBody()
    data: { orderId: string; latitude: number; longitude: number; heading?: number },
  ) {
    const user = client.data.user as JwtPayload | undefined;
    if (!user?.riderProfileId || !data?.orderId) return;
    if (!this.allowAction(client, 'rider:location', 800)) {
      return { ok: false, error: 'rate_limited' };
    }

    // Only the rider actively assigned to this order may publish its location.
    const assignment = await this.prisma.riderAssignment.findFirst({
      where: {
        orderId: data.orderId,
        riderId: user.riderProfileId,
        status: AssignmentStatus.ACCEPTED,
      },
      select: { id: true },
    });
    if (!assignment) {
      this.logger.warn(
        `Rider ${user.riderProfileId} denied rider:location for order ${data.orderId}`,
      );
      return { ok: false, error: 'forbidden' };
    }

    await this.prisma.createRiderLocation({
      riderId: user.riderProfileId,
      latitude: data.latitude,
      longitude: data.longitude,
      heading: data.heading,
    });

    const payload = {
      riderId: user.riderProfileId,
      latitude: data.latitude,
      longitude: data.longitude,
      heading: data.heading,
      recordedAt: new Date().toISOString(),
    };
    this.realtime.emitRiderLocation(data.orderId, payload);
    return { ok: true };
  }
}
