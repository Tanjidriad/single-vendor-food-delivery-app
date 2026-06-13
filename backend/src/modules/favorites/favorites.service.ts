import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class FavoritesService {
  constructor(private prisma: PrismaService) {}

  list(userId: string) {
    return this.prisma.favorite.findMany({
      where: { userId },
      include: {
        menuItem: { include: { addons: { include: { addon: true } } } },
      },
    });
  }

  add(userId: string, menuItemId: string) {
    return this.prisma.favorite.upsert({
      where: { userId_menuItemId: { userId, menuItemId } },
      update: {},
      create: { userId, menuItemId },
    });
  }

  remove(userId: string, menuItemId: string) {
    return this.prisma.favorite.deleteMany({
      where: { userId, menuItemId },
    });
  }
}
