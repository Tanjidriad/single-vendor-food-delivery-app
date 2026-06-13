import { Controller, Get, Param, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { UserRole } from '@prisma/client';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Public } from '../../common/decorators/public.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { JwtPayload } from '../auth/interfaces/jwt-payload.interface';
import { RestaurantService } from './restaurant.service';

@ApiTags('restaurant')
@Controller('restaurant')
export class RestaurantController {
  constructor(private restaurantService: RestaurantService) {}

  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.OWNER, UserRole.MANAGER, UserRole.CASHIER, UserRole.KITCHEN)
  @Get('dashboard/stats')
  dashboard(@CurrentUser() user: JwtPayload) {
    if (!user.restaurantId) {
      return { today: 0, pending: 0, active: 0, completed: 0, cancelled: 0 };
    }
    return this.restaurantService.dashboardStats(user.restaurantId);
  }

  @Public()
  @Get('slug/:slug')
  getBySlug(@Param('slug') slug: string) {
    return this.restaurantService.getBySlug(slug);
  }

  @Public()
  @Get(':id')
  getById(@Param('id') id: string) {
    return this.restaurantService.getById(id);
  }
}
