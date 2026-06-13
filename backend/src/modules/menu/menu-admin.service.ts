import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class MenuAdminService {
  constructor(private prisma: PrismaService) {}

  async getFullMenu(restaurantId: string) {
    return this.prisma.category.findMany({
      where: { restaurantId },
      orderBy: { sortOrder: 'asc' },
      include: {
        menuItems: {
          orderBy: { sortOrder: 'asc' },
          include: {
            addons: { include: { addon: true } },
          },
        },
      },
    });
  }

  // Categories
  createCategory(restaurantId: string, data: Record<string, unknown>) {
    return this.prisma.category.create({
      data: { restaurantId, ...data } as never,
    });
  }

  updateCategory(restaurantId: string, id: string, data: Record<string, unknown>) {
    return this.prisma.category.updateMany({
      where: { id, restaurantId },
      data: data as object,
    });
  }

  deleteCategory(restaurantId: string, id: string) {
    return this.prisma.category.deleteMany({ where: { id, restaurantId } });
  }

  // Menu items
  createItem(restaurantId: string, data: Record<string, unknown>) {
    return this.prisma.menuItem.create({
      data: { restaurantId, ...data } as never,
    });
  }

  updateItem(restaurantId: string, id: string, data: Record<string, unknown>) {
    return this.prisma.menuItem.updateMany({
      where: { id, restaurantId },
      data: data as object,
    });
  }

  deleteItem(restaurantId: string, id: string) {
    return this.prisma.menuItem.deleteMany({ where: { id, restaurantId } });
  }

  async linkAddon(menuItemId: string, addonId: string) {
    return this.prisma.menuItemAddon.create({
      data: { menuItemId, addonId },
    });
  }

  async unlinkAddon(menuItemId: string, addonId: string) {
    return this.prisma.menuItemAddon.delete({
      where: {
        menuItemId_addonId: {
          menuItemId,
          addonId,
        },
      },
    });
  }

  // Addons
  getAddons(restaurantId: string) {
    return this.prisma.addon.findMany({
      where: { restaurantId },
      orderBy: { createdAt: 'desc' },
    });
  }
  createAddon(restaurantId: string, data: Record<string, unknown>) {
    return this.prisma.addon.create({
      data: { restaurantId, ...data } as never,
    });
  }

  updateAddon(restaurantId: string, id: string, data: Record<string, unknown>) {
    return this.prisma.addon.updateMany({
      where: { id, restaurantId },
      data: data as object,
    });
  }

  deleteAddon(restaurantId: string, id: string) {
    return this.prisma.addon.deleteMany({ where: { id, restaurantId } });
  }
}
