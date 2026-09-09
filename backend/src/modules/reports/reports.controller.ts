import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { UserRole } from '@prisma/client';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { requireRestaurantId } from '../../common/utils/staff-restaurant.util';
import { JwtPayload } from '../auth/interfaces/jwt-payload.interface';
import { ReportsService } from './reports.service';

@ApiTags('reports')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.OWNER, UserRole.MANAGER, UserRole.ADMIN)
@Controller('reports')
export class ReportsController {
  constructor(private reports: ReportsService) {}

  @Get('sales')
  sales(
    @CurrentUser() user: JwtPayload,
    @Query('period') period: 'day' | 'week' | 'month' = 'day',
  ) {
    return this.reports.salesSummary(requireRestaurantId(user), period);
  }

  @Get('popular-items')
  popularItems(
    @CurrentUser() user: JwtPayload,
    @Query('limit') limit?: string,
  ) {
    return this.reports.getPopularItems(requireRestaurantId(user), limit ? parseInt(limit, 10) : 4);
  }

  @Get('earnings')
  earnings(
    @CurrentUser() user: JwtPayload,
    @Query('period') period: 'day' | 'week' | 'month' = 'day',
  ) {
    return this.reports.earnings(requireRestaurantId(user), period);
  }

  @Get('riders')
  riders(@CurrentUser() user: JwtPayload) {
    return this.reports.riderPerformance(requireRestaurantId(user));
  }

  @Get('rider/earnings')
  @Roles(UserRole.RIDER)
  riderEarnings(
    @CurrentUser() user: JwtPayload,
    @Query('period') period: 'day' | 'week' | 'month' | 'all' = 'day',
  ) {
    return this.reports.riderEarnings(user.riderProfileId!, period);
  }

  @Get('rider/performance')
  @Roles(UserRole.RIDER)
  riderPerformance(
    @CurrentUser() user: JwtPayload,
    @Query('period') period: 'day' | 'week' | 'month' | 'all' = 'week',
  ) {
    return this.reports.riderQualityMetrics(user.riderProfileId!, period);
  }

  @Get('rider/cash')
  @Roles(UserRole.RIDER)
  riderCash(
    @CurrentUser() user: JwtPayload,
    @Query('period') period: 'day' | 'week' | 'month' | 'all' = 'day',
  ) {
    return this.reports.riderCashSummary(user.riderProfileId!, period);
  }
}
