import { Injectable } from '@nestjs/common';
import { Server } from 'socket.io';

@Injectable()
export class RealtimeService {
  private server?: Server;

  setServer(server: Server) {
    this.server = server;
  }

  emitToRoom(room: string, event: string, payload: unknown) {
    this.server?.to(room).emit(event, payload);
  }

  emitOrderStatus(orderId: string, payload: unknown) {
    this.emitToRoom(`order:${orderId}`, 'order:status.changed', payload);
  }

  emitAssignmentCreated(riderUserId: string, payload: unknown, restaurantId?: string) {
    this.emitToRoom(`rider:${riderUserId}`, 'assignment:created', payload);
    if (typeof payload === 'object' && payload && 'orderId' in payload) {
      this.emitToRoom(
        `order:${(payload as { orderId: string }).orderId}`,
        'assignment:created',
        payload,
      );
    }
    if (restaurantId) {
      this.emitToRoom(`restaurant:${restaurantId}`, 'assignment:created', payload);
    }
  }

  emitAssignmentAccepted(orderId: string, payload: unknown, restaurantId?: string) {
    this.emitToRoom(`order:${orderId}`, 'assignment:accepted', payload);
    if (restaurantId) {
      this.emitToRoom(`restaurant:${restaurantId}`, 'assignment:accepted', payload);
    }
  }

  emitAssignmentRejected(orderId: string, payload: unknown, restaurantId?: string) {
    this.emitToRoom(`order:${orderId}`, 'assignment:rejected', payload);
    if (restaurantId) {
      this.emitToRoom(`restaurant:${restaurantId}`, 'assignment:rejected', payload);
    }
  }

  emitAssignmentExpired(
    orderId: string,
    payload: unknown,
    restaurantId?: string,
    riderUserId?: string,
  ) {
    this.emitToRoom(`order:${orderId}`, 'assignment:expired', payload);
    if (restaurantId) {
      this.emitToRoom(`restaurant:${restaurantId}`, 'assignment:expired', payload);
    }
    // The offered rider has not joined the `order:` room yet (that happens on
    // accept), so also notify their personal room — mirrors how
    // `assignment:created` is delivered — otherwise a rider staring at a live
    // offer never learns it expired server-side.
    if (riderUserId) {
      this.emitToRoom(`rider:${riderUserId}`, 'assignment:expired', payload);
    }
  }

  emitRiderLocation(orderId: string, payload: unknown) {
    this.emitToRoom(`order:${orderId}`, 'rider:location.updated', payload);
  }

  emitRestaurantNewOrder(restaurantId: string, payload: unknown) {
    this.emitToRoom(`restaurant:${restaurantId}`, 'order:created', payload);
  }
}
