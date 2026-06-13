import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { OrderStatus } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class ReviewsService {
  constructor(private prisma: PrismaService) {}

  async create(userId: string, orderId: string, rating: number, comment?: string) {
    const order = await this.prisma.order.findUnique({ where: { id: orderId } });
    if (!order || order.customerId !== userId) {
      throw new NotFoundException('Order not found');
    }
    if (order.status !== OrderStatus.DELIVERED) {
      throw new BadRequestException('Order must be delivered before review');
    }
    if (rating < 1 || rating > 5) {
      throw new BadRequestException('Rating must be 1-5');
    }
    return this.prisma.review.create({
      data: { orderId, userId, rating, comment },
    });
  }

  listByRestaurant(restaurantId: string) {
    return this.prisma.review.findMany({
      where: { order: { restaurantId } },
      include: { user: { select: { id: true, customerProfile: true } } },
      orderBy: { createdAt: 'desc' },
      take: 50,
    });
  }
}
