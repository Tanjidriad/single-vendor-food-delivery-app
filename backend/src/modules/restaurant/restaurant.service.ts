import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class RestaurantService {
  constructor(private prisma: PrismaService) {}

  async getBySlug(slug: string) {
    const restaurant = await this.prisma.restaurant.findUnique({
      where: { slug },
      include: {
        settings: true,
        operatingHours: { orderBy: { dayOfWeek: 'asc' } },
        deliveryFeeConfig: true,
      },
    });
    if (!restaurant) throw new NotFoundException('Restaurant not found');
    return restaurant;
  }

  async getById(id: string) {
    const restaurant = await this.prisma.restaurant.findUnique({
      where: { id },
      include: {
        settings: true,
        operatingHours: { orderBy: { dayOfWeek: 'asc' } },
        deliveryFeeConfig: true,
      },
    });
    if (!restaurant) throw new NotFoundException('Restaurant not found');
    return restaurant;
  }

  async dashboardStats(restaurantId: string) {
    const startOfDay = new Date();
    startOfDay.setHours(0, 0, 0, 0);

    const [today, pending, active, completed, cancelled] = await Promise.all([
      this.prisma.order.count({
        where: { restaurantId, placedAt: { gte: startOfDay } },
      }),
      this.prisma.order.count({
        where: {
          restaurantId,
          status: { in: ['PLACED', 'ACCEPTED', 'PREPARING'] },
        },
      }),
      this.prisma.order.count({
        where: {
          restaurantId,
          status: {
            in: ['READY_FOR_PICKUP', 'PICKED_UP', 'ON_THE_WAY'],
          },
        },
      }),
      this.prisma.order.count({
        where: { restaurantId, status: 'DELIVERED', placedAt: { gte: startOfDay } },
      }),
      this.prisma.order.count({
        where: { restaurantId, status: 'CANCELLED', placedAt: { gte: startOfDay } },
      }),
    ]);

    return { today, pending, active, completed, cancelled };
  }
}
