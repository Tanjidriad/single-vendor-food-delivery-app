import { Module } from '@nestjs/common';
import { CodSettlementService } from './cod-settlement.service';
import { EarningsController } from './earnings.controller';
import { RiderLedgerService } from './rider-ledger.service';

@Module({
  controllers: [EarningsController],
  providers: [RiderLedgerService, CodSettlementService],
  exports: [RiderLedgerService, CodSettlementService],
})
export class EarningsModule {}
