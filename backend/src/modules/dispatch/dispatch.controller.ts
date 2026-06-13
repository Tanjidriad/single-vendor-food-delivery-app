import { Body, Controller, Get, Param, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { UserRole } from '@prisma/client';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { JwtPayload } from '../auth/interfaces/jwt-payload.interface';
import { requireRestaurantId } from '../../common/utils/staff-restaurant.util';
import { AcceptBatchDto } from './dto/accept-batch.dto';
import { AssignRiderDto } from './dto/assign-rider.dto';
import { DispatchService } from './dispatch.service';

@ApiTags('dispatch')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller()
export class DispatchController {
  constructor(private dispatchService: DispatchService) { }

  @Get('dispatch/riders/available')
  @Roles(UserRole.OWNER, UserRole.MANAGER, UserRole.CASHIER)
  listRiders(@CurrentUser() user: JwtPayload) {
    return this.dispatchService.listAvailableRiders(
      requireRestaurantId(user),
    );
  }

  @Post('dispatch/orders/:orderId/auto-assign')
  @Roles(UserRole.OWNER, UserRole.MANAGER, UserRole.CASHIER)
  autoAssign(@CurrentUser() user: JwtPayload, @Param('orderId') orderId: string) {
    return this.dispatchService.autoAssign(user, orderId);
  }

  @Post('dispatch/orders/:orderId/assign')
  @Roles(UserRole.OWNER, UserRole.MANAGER, UserRole.CASHIER)
  assign(
    @CurrentUser() user: JwtPayload,
    @Param('orderId') orderId: string,
    @Body() dto: AssignRiderDto,
  ) {
    return this.dispatchService.assign(user, orderId, dto);
  }

  @Get('rider/assignments/pending')
  @Roles(UserRole.RIDER)
  listPending(@CurrentUser() user: JwtPayload) {
    return this.dispatchService.listPendingForRider(user);
  }

  @Post('rider/assignments/accept-batch')
  @Roles(UserRole.RIDER)
  acceptBatch(@CurrentUser() user: JwtPayload, @Body() dto: AcceptBatchDto) {
    return this.dispatchService.acceptBatch(user, dto.assignmentIds);
  }

  @Post('rider/assignments/:id/accept')
  @Roles(UserRole.RIDER)
  accept(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    return this.dispatchService.accept(user, id);
  }

  @Post('rider/assignments/:id/reject')
  @Roles(UserRole.RIDER)
  reject(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    return this.dispatchService.reject(user, id);
  }

  @Post('dispatch/orders/:orderId/force-unassign')
  @Roles(UserRole.OWNER, UserRole.MANAGER, UserRole.CASHIER, UserRole.ADMIN)
  forceUnassign(
    @CurrentUser() user: JwtPayload,
    @Param('orderId') orderId: string,
    @Body() body: { reason?: string },
  ) {
    return this.dispatchService.forceUnassign(user, orderId, body?.reason);
  }
}
