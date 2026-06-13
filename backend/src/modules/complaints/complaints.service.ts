import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { OrderStatus } from '@prisma/client';
import { ComplaintStatus, ComplaintType } from '../../common/enums/complaint.enum';
import { PrismaService } from '../../prisma/prisma.service';
import { JwtPayload } from '../auth/interfaces/jwt-payload.interface';
import { CreateComplaintDto } from './dto/create-complaint.dto';
import { UpdateComplaintDto } from './dto/update-complaint.dto';

@Injectable()
export class ComplaintsService {
  constructor(private prisma: PrismaService) {}

  async create(userId: string, dto: CreateComplaintDto) {
    const order = await this.prisma.order.findUnique({ where: { id: dto.orderId } });
    if (!order || order.customerId !== userId) {
      throw new NotFoundException('Order not found');
    }
    const allowedStatuses: OrderStatus[] = [
      OrderStatus.DELIVERED,
      OrderStatus.CANCELLED,
    ];
    if (!allowedStatuses.includes(order.status)) {
      throw new BadRequestException(
        'Complaints are only allowed for delivered or cancelled orders',
      );
    }
    if (
      dto.type === ComplaintType.REFUND_REQUEST &&
      order.status !== OrderStatus.DELIVERED
    ) {
      throw new BadRequestException(
        'Refund requests require a delivered order',
      );
    }
    if (dto.refundAmount != null && dto.refundAmount > order.grandTotal) {
      throw new BadRequestException('Refund amount cannot exceed order total');
    }

    const existing = await this.prisma.complaint.findFirst({
      where: {
        orderId: dto.orderId,
        userId,
        status: { in: [ComplaintStatus.OPEN, ComplaintStatus.IN_REVIEW] },
      },
    });
    if (existing) {
      throw new BadRequestException('An open complaint already exists for this order');
    }

    return this.prisma.complaint.create({
      data: {
        orderId: dto.orderId,
        userId,
        restaurantId: order.restaurantId,
        type: dto.type,
        subject: dto.subject,
        description: dto.description,
        refundAmount: dto.refundAmount,
      },
      include: {
        order: { select: { id: true, orderNumber: true, status: true, grandTotal: true } },
      },
    });
  }

  listMine(userId: string) {
    return this.prisma.complaint.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      include: {
        order: { select: { id: true, orderNumber: true, status: true } },
      },
    });
  }

  listForRestaurant(restaurantId: string, status?: ComplaintStatus) {
    return this.prisma.complaint.findMany({
      where: {
        restaurantId,
        status: status ?? undefined,
      },
      orderBy: { createdAt: 'desc' },
      include: {
        user: {
          select: {
            id: true,
            email: true,
            phone: true,
            customerProfile: { select: { fullName: true } },
          },
        },
        order: { select: { id: true, orderNumber: true, grandTotal: true, status: true } },
      },
    });
  }

  async update(staff: JwtPayload, id: string, dto: UpdateComplaintDto) {
    const complaint = await this.prisma.complaint.findUnique({
      where: { id },
      include: { order: true },
    });
    if (!complaint) throw new NotFoundException('Complaint not found');
    if (staff.restaurantId !== complaint.restaurantId) {
      throw new ForbiddenException();
    }
    if (
      dto.refundAmount != null &&
      dto.refundAmount > complaint.order.grandTotal
    ) {
      throw new BadRequestException('Refund amount cannot exceed order total');
    }

    return this.prisma.complaint.update({
      where: { id },
      data: {
        status: dto.status,
        staffNote: dto.staffNote,
        refundAmount: dto.refundAmount,
      },
      include: {
        user: {
          select: {
            id: true,
            email: true,
            customerProfile: { select: { fullName: true } },
          },
        },
        order: { select: { id: true, orderNumber: true, grandTotal: true } },
      },
    });
  }
}
