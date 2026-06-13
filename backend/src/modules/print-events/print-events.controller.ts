import { Body, Controller, Get, Param, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { UserRole } from '@prisma/client';
import { IsOptional, IsString } from 'class-validator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { requireRestaurantId } from '../../common/utils/staff-restaurant.util';
import { JwtPayload } from '../auth/interfaces/jwt-payload.interface';
import { PrintEventsService } from './print-events.service';

class PrintLogDto {
  @IsString()
  orderId: string;

  @IsString()
  printType: 'KITCHEN_TICKET' | 'CUSTOMER_RECEIPT';

  @IsString()
  status: 'REQUESTED' | 'SUCCESS' | 'FAILED';

  @IsOptional()
  @IsString()
  deviceInfo?: string;
}

@ApiTags('print-events')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('print-events')
export class PrintEventsController {
  constructor(private printEvents: PrintEventsService) {}

  @Post('log')
  @Roles(UserRole.OWNER, UserRole.MANAGER, UserRole.CASHIER, UserRole.KITCHEN)
  log(@CurrentUser() user: JwtPayload, @Body() dto: PrintLogDto) {
    return this.printEvents.logAndEmit({
      ...dto,
      restaurantId: requireRestaurantId(user),
    });
  }

  @Get('orders/:orderId')
  @Roles(UserRole.OWNER, UserRole.MANAGER, UserRole.CASHIER, UserRole.KITCHEN)
  list(@Param('orderId') orderId: string) {
    return this.printEvents.listByOrder(orderId);
  }
}
