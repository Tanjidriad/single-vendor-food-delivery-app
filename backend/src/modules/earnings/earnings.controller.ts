import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { UserRole } from '@prisma/client';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { requireRestaurantId } from '../../common/utils/staff-restaurant.util';
import { JwtPayload } from '../auth/interfaces/jwt-payload.interface';
import { CodSettlementService } from './cod-settlement.service';
import { CreateRiderPayoutDto } from './dto/create-rider-payout.dto';
import { SettleCodDto } from './dto/settle-cod.dto';
import { RiderLedgerService } from './rider-ledger.service';

@ApiTags('earnings')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('earnings')
export class EarningsController {
  constructor(
    private ledger: RiderLedgerService,
    private cod: CodSettlementService,
  ) {}

  @ApiOperation({ summary: 'Rider ledger balance and recent entries' })
  @Get('riders/:riderId/ledger')
  @Roles(UserRole.OWNER, UserRole.MANAGER, UserRole.ADMIN)
  async riderLedger(@Param('riderId') riderId: string) {
    const [balance, entries, payouts] = await Promise.all([
      this.ledger.getRiderBalance(riderId),
      this.ledger.listLedger(riderId),
      this.ledger.listPayouts(riderId),
    ]);
    return { riderId, balance, entries, payouts };
  }

  @ApiOperation({ summary: 'Record a completed rider payout' })
  @Post('riders/:riderId/payouts')
  @Roles(UserRole.OWNER, UserRole.MANAGER, UserRole.ADMIN)
  createPayout(
    @CurrentUser() user: JwtPayload,
    @Param('riderId') riderId: string,
    @Body() dto: CreateRiderPayoutDto,
  ) {
    return this.ledger.createPayout({
      riderId,
      amount: dto.amount,
      createdBy: user.sub,
      reference: dto.reference,
      note: dto.note,
    });
  }

  @ApiOperation({ summary: 'List pending COD remittances' })
  @Get('cod-settlements/pending')
  @Roles(UserRole.OWNER, UserRole.MANAGER, UserRole.ADMIN)
  pendingCod(
    @CurrentUser() user: JwtPayload,
    @Query('restaurantId') restaurantId?: string,
  ) {
    const scopedRestaurantId =
      user.role === UserRole.ADMIN
        ? restaurantId
        : requireRestaurantId(user);
    return this.cod.listPending(scopedRestaurantId);
  }

  @ApiOperation({ summary: 'Mark COD food remittance as settled' })
  @Post('cod-settlements/:orderId/settle')
  @Roles(UserRole.OWNER, UserRole.MANAGER, UserRole.ADMIN)
  settleCod(
    @CurrentUser() user: JwtPayload,
    @Param('orderId') orderId: string,
    @Body() dto: SettleCodDto,
  ) {
    return this.cod.settle({
      orderId,
      settledBy: user.sub,
      foodAmountRemitted: dto.foodAmountRemitted,
      note: dto.note,
    });
  }
}
