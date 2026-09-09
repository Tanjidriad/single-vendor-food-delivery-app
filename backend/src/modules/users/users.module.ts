import { Module } from '@nestjs/common';
import { BullModule } from '@nestjs/bullmq';
import { DISPATCH_QUEUE } from '../../common/queues/queue.constants';
import { UsersController } from './users.controller';
import { UsersService } from './users.service';

@Module({
  imports: [BullModule.registerQueue({ name: DISPATCH_QUEUE })],
  controllers: [UsersController],
  providers: [UsersService],
  exports: [UsersService],
})
export class UsersModule {}
