import { Body, Controller, Get, Param, Patch, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { UserRole } from '@prisma/client';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { JwtPayload } from '../auth/interfaces/jwt-payload.interface';
import { requireRestaurantId } from '../../common/utils/staff-restaurant.util';
import {
  CreateRefundRequestDto,
  UpdateRefundRequestDto,
} from './dto/refund-request.dto';
import { RefundsService } from './refunds.service';

@ApiTags('refunds')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('admin/refunds')
export class RefundsController {
  constructor(private refundsService: RefundsService) {}

  @Get('pending')
  @Roles(UserRole.OWNER, UserRole.MANAGER, UserRole.ADMIN)
  listPending(@CurrentUser() user: JwtPayload) {
    const restaurantId =
      user.role === UserRole.ADMIN ? undefined : requireRestaurantId(user);
    return this.refundsService.listPending(restaurantId);
  }

  @Post()
  @Roles(UserRole.OWNER, UserRole.MANAGER, UserRole.ADMIN)
  create(@Body() dto: CreateRefundRequestDto) {
    return this.refundsService.create(dto);
  }

  @Patch(':id')
  @Roles(UserRole.OWNER, UserRole.MANAGER, UserRole.ADMIN)
  update(@Param('id') id: string, @Body() dto: UpdateRefundRequestDto) {
    return this.refundsService.update(id, dto);
  }
}
