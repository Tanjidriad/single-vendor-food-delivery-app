import { Body, Controller, Param, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { UserRole } from '@prisma/client';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { JwtPayload } from '../auth/interfaces/jwt-payload.interface';
import { ExecutePaymentDto } from './dto/execute-payment.dto';
import { PaymentsService } from './payments.service';

@ApiTags('payments')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('payments')
export class PaymentsController {
  constructor(private payments: PaymentsService) {}

  @Post('orders/:orderId/online/initiate')
  @Roles(UserRole.CUSTOMER)
  initiate(@CurrentUser() user: JwtPayload, @Param('orderId') orderId: string) {
    return this.payments.initiateOnline(orderId, user.sub);
  }

  @Post('orders/:orderId/online/execute')
  @Roles(UserRole.CUSTOMER)
  execute(
    @CurrentUser() user: JwtPayload,
    @Param('orderId') orderId: string,
    @Body() dto: ExecutePaymentDto,
  ) {
    return this.payments.executeOnline(orderId, user.sub, dto.paymentId);
  }

  @Post('orders/:orderId/wallet')
  @Roles(UserRole.CUSTOMER)
  wallet(@CurrentUser() user: JwtPayload, @Param('orderId') orderId: string) {
    return this.payments.walletPay(orderId, user.sub);
  }
}
