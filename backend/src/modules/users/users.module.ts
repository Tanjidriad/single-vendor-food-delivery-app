import { Module } from '@nestjs/common';
import { DispatchModule } from '../dispatch/dispatch.module';
import { UsersController } from './users.controller';
import { UsersService } from './users.service';

@Module({
  imports: [DispatchModule],
  controllers: [UsersController],
  providers: [UsersService],
  exports: [UsersService],
})
export class UsersModule {}
