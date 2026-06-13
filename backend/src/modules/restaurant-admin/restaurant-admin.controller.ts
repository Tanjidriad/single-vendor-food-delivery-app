import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseIntPipe,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { UserRole } from '@prisma/client';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { requireRestaurantId } from '../../common/utils/staff-restaurant.util';
import { JwtPayload } from '../auth/interfaces/jwt-payload.interface';
import { RestaurantAdminService } from './restaurant-admin.service';
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

@ApiTags('restaurant-admin')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.OWNER, UserRole.MANAGER, UserRole.ADMIN)
@Controller('admin/restaurant')
export class RestaurantAdminController {
  constructor(private admin: RestaurantAdminService) {}

  @Patch('profile')
  updateProfile(@CurrentUser() user: JwtPayload, @Body() body: UpdateRestaurantProfileDto) {
    return this.admin.updateRestaurant(requireRestaurantId(user), body);
  }

  @Patch('settings')
  settings(@CurrentUser() user: JwtPayload, @Body() body: UpdateSettingsDto) {
    return this.admin.updateSettings(requireRestaurantId(user), body);
  }

  @Patch('delivery-fee')
  feeConfig(@CurrentUser() user: JwtPayload, @Body() body: UpdateFeeConfigDto) {
    return this.admin.updateFeeConfig(requireRestaurantId(user), body);
  }

  @Post('operating-hours/:day')
  hours(
    @CurrentUser() user: JwtPayload,
    @Param('day', ParseIntPipe) day: number,
    @Body() body: UpdateOperatingHourDto,
  ) {
    return this.admin.upsertOperatingHour(requireRestaurantId(user), day, body);
  }

  @Get('banners')
  listBanners(@CurrentUser() user: JwtPayload) {
    return this.admin.listBanners(requireRestaurantId(user));
  }

  @Post('banners')
  createBanner(@CurrentUser() user: JwtPayload, @Body() body: CreateBannerDto) {
    return this.admin.createBanner(requireRestaurantId(user), body);
  }

  @Patch('banners/:id')
  updateBanner(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
    @Body() body: UpdateBannerDto,
  ) {
    return this.admin.updateBanner(requireRestaurantId(user), id, body);
  }

  @Delete('banners/:id')
  deleteBanner(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    return this.admin.deleteBanner(requireRestaurantId(user), id);
  }

  @Get('coupons')
  listCoupons(@CurrentUser() user: JwtPayload) {
    return this.admin.listCoupons(requireRestaurantId(user));
  }

  @Post('coupons')
  createCoupon(@CurrentUser() user: JwtPayload, @Body() body: CreateCouponDto) {
    return this.admin.createCoupon(requireRestaurantId(user), body);
  }

  @Patch('coupons/:id')
  updateCoupon(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
    @Body() body: UpdateCouponDto,
  ) {
    return this.admin.updateCoupon(requireRestaurantId(user), id, body);
  }

  @Delete('coupons/:id')
  deleteCoupon(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    return this.admin.deleteCoupon(requireRestaurantId(user), id);
  }

  @Get('zones')
  listZones(@CurrentUser() user: JwtPayload) {
    return this.admin.listZones(requireRestaurantId(user));
  }

  @Post('zones')
  createZone(@CurrentUser() user: JwtPayload, @Body() body: CreateZoneDto) {
    return this.admin.createZone(requireRestaurantId(user), body);
  }

  @Patch('zones/:id')
  updateZone(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
    @Body() body: UpdateZoneDto,
  ) {
    return this.admin.updateZone(requireRestaurantId(user), id, body);
  }

  @Delete('zones/:id')
  deleteZone(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    return this.admin.deleteZone(requireRestaurantId(user), id);
  }
}
