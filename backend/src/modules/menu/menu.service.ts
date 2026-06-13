import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class MenuService {
  constructor(private prisma: PrismaService) {}

  async getPublicMenu(restaurantId: string) {
    return this.prisma.category.findMany({
      where: { restaurantId, isActive: true },
      orderBy: { sortOrder: 'asc' },
      include: {
        menuItems: {
          where: { isAvailable: true },
          orderBy: { sortOrder: 'asc' },
          include: {
            addons: { include: { addon: true } },
          },
        },
      },
    });
  }

  async getFeatured(restaurantId: string) {
    return this.prisma.menuItem.findMany({
      where: { restaurantId, isFeatured: true, isAvailable: true },
      take: 10,
      include: { addons: { include: { addon: true } } },
    });
  }

  async getItem(itemId: string) {
    const item = await this.prisma.menuItem.findUnique({
      where: { id: itemId },
      include: {
        category: true,
        addons: { include: { addon: true } },
      },
    });
    if (!item) throw new NotFoundException('Menu item not found');
    return item;
  }

  getBanners(restaurantId: string) {
    return this.prisma.banner.findMany({
      where: {
        restaurantId,
        isActive: true,
        OR: [
          { startsAt: null, endsAt: null },
          { startsAt: { lte: new Date() }, endsAt: null },
          { startsAt: null, endsAt: { gte: new Date() } },
          { startsAt: { lte: new Date() }, endsAt: { gte: new Date() } },
        ],
      },
      orderBy: { sortOrder: 'asc' },
    });
  }

  async filter(restaurantId: string, query: {
    categoryId?: string;
    minPrice?: number;
    maxPrice?: number;
    availableOnly?: boolean;
    featuredOnly?: boolean;
    q?: string;
  }) {
    return this.prisma.menuItem.findMany({
      where: {
        restaurantId,
        isAvailable: query.availableOnly === false ? undefined : true,
        isFeatured: query.featuredOnly ? true : undefined,
        categoryId: query.categoryId,
        price: {
          gte: query.minPrice,
          lte: query.maxPrice,
        },
        OR: query.q
          ? [
              { name: { contains: query.q, mode: 'insensitive' } },
              { description: { contains: query.q, mode: 'insensitive' } },
            ]
          : undefined,
      },
      orderBy: { sortOrder: 'asc' },
      take: 50,
      include: {
        category: true,
        addons: { include: { addon: true } },
      },
    });
  }

  async search(restaurantId: string, q: string) {
    return this.prisma.menuItem.findMany({
      where: {
        restaurantId,
        isAvailable: true,
        OR: [
          { name: { contains: q, mode: 'insensitive' } },
          { description: { contains: q, mode: 'insensitive' } },
        ],
      },
      take: 30,
      include: { addons: { include: { addon: true } } },
    });
  }
}
