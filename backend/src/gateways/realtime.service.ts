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

  emitAssignmentCreated(riderUserId: string, payload: unknown) {
    this.emitToRoom(`rider:${riderUserId}`, 'assignment:created', payload);
    if (typeof payload === 'object' && payload && 'orderId' in payload) {
      this.emitToRoom(
        `order:${(payload as { orderId: string }).orderId}`,
        'assignment:created',
        payload,
      );
    }
  }

  emitAssignmentAccepted(orderId: string, payload: unknown) {
    this.emitToRoom(`order:${orderId}`, 'assignment:accepted', payload);
  }

  emitAssignmentRejected(orderId: string, payload: unknown) {
    this.emitToRoom(`order:${orderId}`, 'assignment:rejected', payload);
  }

  emitAssignmentExpired(orderId: string, payload: unknown) {
    this.emitToRoom(`order:${orderId}`, 'assignment:expired', payload);
  }

  emitRiderLocation(orderId: string, payload: unknown) {
    this.emitToRoom(`order:${orderId}`, 'rider:location.updated', payload);
  }

  emitRestaurantNewOrder(restaurantId: string, payload: unknown) {
    this.emitToRoom(`restaurant:${restaurantId}`, 'order:created', payload);
  }
}
