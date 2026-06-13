import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateBannerDto } from './dto/create-banner.dto';
import { UpdateBannerDto } from './dto/update-banner.dto';
import { CreateCouponDto } from './dto/create-coupon.dto';
import { UpdateCouponDto } from './dto/update-coupon.dto';
import { CreateZoneDto } from './dto/create-zone.dto';
import { UpdateZoneDto } from './dto/update-zone.dto';
import { UpdateSettingsDto } from './dto/update-settings.dto';
import { UpdateFeeConfigDto } from './dto/update-fee-config.dto';
import { UpdateOperatingHourDto } from './dto/update-operating-hour.dto';
import { UpdateRestaurantProfileDto } from './dto/update-restaurant-profile.dto';

@Injectable()
export class RestaurantAdminService {
  constructor(private prisma: PrismaService) {}

  // Banners
  listBanners(restaurantId: string) {
    return this.prisma.banner.findMany({
      where: { restaurantId },
      orderBy: { sortOrder: 'asc' },
    });
  }

  createBanner(restaurantId: string, data: CreateBannerDto) {
    return this.prisma.banner.create({
      data: { restaurantId, ...data },
    });
  }

  updateBanner(restaurantId: string, id: string, data: UpdateBannerDto) {
    return this.prisma.banner.updateMany({
      where: { id, restaurantId },
      data,
    });
  }

  deleteBanner(restaurantId: string, id: string) {
    return this.prisma.banner.deleteMany({ where: { id, restaurantId } });
  }

  // Coupons
  listCoupons(restaurantId: string) {
    return this.prisma.coupon.findMany({ where: { restaurantId } });
  }

  createCoupon(restaurantId: string, data: CreateCouponDto) {
    return this.prisma.coupon.create({
      data: { restaurantId, ...data },
    });
  }

  updateCoupon(restaurantId: string, id: string, data: UpdateCouponDto) {
    return this.prisma.coupon.updateMany({
      where: { id, restaurantId },
      data,
    });
  }

  deleteCoupon(restaurantId: string, id: string) {
    return this.prisma.coupon.deleteMany({ where: { id, restaurantId } });
  }

  // Zones
  listZones(restaurantId: string) {
    return this.prisma.deliveryZone.findMany({ where: { restaurantId } });
  }

  createZone(restaurantId: string, data: CreateZoneDto) {
    return this.prisma.deliveryZone.create({
      data: { restaurantId, ...data },
    });
  }

  updateZone(restaurantId: string, id: string, data: UpdateZoneDto) {
    return this.prisma.deliveryZone.updateMany({
      where: { id, restaurantId },
      data,
    });
  }

  deleteZone(restaurantId: string, id: string) {
    return this.prisma.deliveryZone.deleteMany({ where: { id, restaurantId } });
  }

  // Settings
  updateSettings(restaurantId: string, data: UpdateSettingsDto) {
    return this.prisma.restaurantSettings.upsert({
      where: { restaurantId },
      create: { restaurantId, ...data },
      update: data,
    });
  }

  updateFeeConfig(restaurantId: string, data: UpdateFeeConfigDto) {
    return this.prisma.deliveryFeeConfig.upsert({
      where: { restaurantId },
      create: { restaurantId, ...data },
      update: data,
    });
  }

  upsertOperatingHour(
    restaurantId: string,
    dayOfWeek: number,
    data: UpdateOperatingHourDto,
  ) {
    return this.prisma.operatingHour.upsert({
      where: { restaurantId_dayOfWeek: { restaurantId, dayOfWeek } },
      create: { restaurantId, dayOfWeek, ...data },
      update: data,
    });
  }

  updateRestaurant(restaurantId: string, data: UpdateRestaurantProfileDto) {
    return this.prisma.restaurant.update({
      where: { id: restaurantId },
      data,
    });
  }
}
