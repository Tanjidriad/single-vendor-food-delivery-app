import { Module } from '@nestjs/common';
import { ComplaintsAdminController } from './complaints-admin.controller';
import { ComplaintsController } from './complaints.controller';
import { ComplaintsService } from './complaints.service';

@Module({
  controllers: [ComplaintsController, ComplaintsAdminController],
  providers: [ComplaintsService],
})
export class ComplaintsModule {}
