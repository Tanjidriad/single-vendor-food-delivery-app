import { Module } from '@nestjs/common';
import { RealtimeModule } from '../../gateways/realtime.module';
import { PrintEventsController } from './print-events.controller';
import { PrintEventsService } from './print-events.service';

@Module({
  imports: [RealtimeModule],
  controllers: [PrintEventsController],
  providers: [PrintEventsService],
  exports: [PrintEventsService],
})
export class PrintEventsModule {}
