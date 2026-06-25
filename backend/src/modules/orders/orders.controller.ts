import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { UserRole } from '@prisma/client';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { PaginationDto } from '../../common/dto/pagination.dto';
import { JwtPayload } from '../auth/interfaces/jwt-payload.interface';
import { AcceptOrderDto } from './dto/accept-order.dto';
import { CancelOrderDto } from './dto/cancel-order.dto';
import { DispatchExternalDto } from './dto/dispatch-external.dto';
import { PlaceOrderDto } from './dto/place-order.dto';
import { UpdateOrderStatusDto } from './dto/update-order-status.dto';
import { VerifyDeliveryDto } from './dto/verify-delivery.dto';
import { DeliveryExceptionDto } from './dto/delivery-exception.dto';
import { ResolveExceptionDto } from './dto/resolve-exception.dto';
import { FoodDispositionDto } from './dto/food-disposition.dto';
import { RejectOrderDto } from './dto/reject-order.dto';
import { OrdersService } from './orders.service';

@ApiTags('orders')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('orders')
export class OrdersController {
  constructor(private ordersService: OrdersService) {}

  @Post()
  @Roles(UserRole.CUSTOMER)
  place(@CurrentUser() user: JwtPayload, @Body() dto: PlaceOrderDto) {
    return this.ordersService.placeOrder(user.sub, dto);
  }

  @Get()
  @Roles(
    UserRole.CUSTOMER,
    UserRole.OWNER,
    UserRole.MANAGER,
    UserRole.CASHIER,
    UserRole.KITCHEN,
    UserRole.RIDER,
  )
  list(@CurrentUser() user: JwtPayload, @Query() pagination: PaginationDto) {
    return this.ordersService.listForUser(
      user,
      pagination.page,
      pagination.limit,
    );
  }

  @Get('kitchen/history')
  @Roles(UserRole.OWNER, UserRole.MANAGER, UserRole.CASHIER, UserRole.KITCHEN)
  getKitchenHistory(
    @CurrentUser() user: JwtPayload,
    @Query('date') date?: string,
    @Query('includeTest') includeTest?: string,
  ) {
    return this.ordersService.getKitchenHistory(
      user,
      date,
      includeTest === 'true',
    );
  }

  @Get('kitchen/stats')
  @Roles(UserRole.OWNER, UserRole.MANAGER, UserRole.CASHIER, UserRole.KITCHEN)
  getKitchenStats(
    @CurrentUser() user: JwtPayload,
    @Query('period') period?: string,
    @Query('includeTest') includeTest?: string,
  ) {
    return this.ordersService.getKitchenStats(
      user,
      period,
      includeTest === 'true',
    );
  }

  @Post(':id/accept')
  @Roles(UserRole.OWNER, UserRole.MANAGER, UserRole.CASHIER, UserRole.KITCHEN)
  accept(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
    @Body() dto: AcceptOrderDto,
  ) {
    return this.ordersService.acceptOrder(user, id, dto.prepMinutes);
  }

  @Post(':id/reject')
  @Roles(UserRole.OWNER, UserRole.MANAGER, UserRole.CASHIER, UserRole.KITCHEN)
  reject(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
    @Body() dto: RejectOrderDto,
  ) {
    return this.ordersService.rejectOrder(user, id, dto.note);
  }

  @Post(':id/cancel')
  @Roles(
    UserRole.CUSTOMER,
    UserRole.OWNER,
    UserRole.MANAGER,
    UserRole.CASHIER,
  )
  cancel(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
    @Body() dto: CancelOrderDto,
  ) {
    return this.ordersService.cancelOrder(user, id, dto);
  }

  @Post(':id/reorder')
  @Roles(UserRole.CUSTOMER)
  reorder(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    return this.ordersService.reorder(user, id);
  }

  @Post(':id/delivery-exception')
  @Roles(UserRole.RIDER)
  reportDeliveryException(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
    @Body() dto: DeliveryExceptionDto,
  ) {
    return this.ordersService.reportDeliveryException(user, id, dto);
  }

  @Post(':id/resolve-exception')
  @Roles(UserRole.OWNER, UserRole.MANAGER, UserRole.CASHIER, UserRole.ADMIN)
  resolveException(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
    @Body() dto: ResolveExceptionDto,
  ) {
    return this.ordersService.resolveDeliveryException(user, id, dto);
  }

  @Post(':id/food-disposition')
  @Roles(UserRole.OWNER, UserRole.MANAGER, UserRole.CASHIER, UserRole.KITCHEN)
  setFoodDisposition(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
    @Body() dto: FoodDispositionDto,
  ) {
    return this.ordersService.setFoodDisposition(user, id, dto);
  }

  @Get('ops/queues')
  @Roles(UserRole.OWNER, UserRole.MANAGER, UserRole.CASHIER, UserRole.ADMIN)
  opsQueues(@CurrentUser() user: JwtPayload) {
    return this.ordersService.listOpsQueues(user);
  }

  @Post(':id/verify-delivery')
  @Roles(UserRole.RIDER)
  verifyDelivery(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
    @Body() dto: VerifyDeliveryDto,
  ) {
    return this.ordersService.verifyDeliveryOtp(user, id, dto);
  }

  @Post(':id/dispatch-external')
  @Roles(UserRole.OWNER, UserRole.MANAGER, UserRole.CASHIER)
  dispatchExternal(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
    @Body() dto: DispatchExternalDto,
  ) {
    return this.ordersService.dispatchExternal(user, id, dto);
  }

  @Post(':id/confirm-delivery')
  @Roles(UserRole.CUSTOMER)
  confirmDelivery(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
  ) {
    return this.ordersService.confirmDeliveryByCustomer(user, id);
  }

  @Get(':id')
  @Roles(
    UserRole.CUSTOMER,
    UserRole.OWNER,
    UserRole.MANAGER,
    UserRole.CASHIER,
    UserRole.KITCHEN,
    UserRole.RIDER,
  )
  getOne(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    return this.ordersService.findOne(user, id);
  }

  @Patch(':id/status')
  @Roles(
    UserRole.OWNER,
    UserRole.MANAGER,
    UserRole.CASHIER,
    UserRole.KITCHEN,
    UserRole.RIDER,
  )
  updateStatus(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
    @Body() dto: UpdateOrderStatusDto,
  ) {
    return this.ordersService.updateStatus(user, id, dto);
  }
}
