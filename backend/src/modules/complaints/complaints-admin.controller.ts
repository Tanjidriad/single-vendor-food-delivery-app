import { Body, Controller, Get, Param, Patch, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { UserRole } from '@prisma/client';
import { ComplaintStatus } from '../../common/enums/complaint.enum';
import { IsEnum, IsOptional } from 'class-validator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { requireRestaurantId } from '../../common/utils/staff-restaurant.util';
import { JwtPayload } from '../auth/interfaces/jwt-payload.interface';
import { ComplaintsService } from './complaints.service';
import { UpdateComplaintDto } from './dto/update-complaint.dto';

class ListComplaintsQuery {
  @IsOptional()
  @IsEnum(ComplaintStatus)
  status?: ComplaintStatus;
}

@ApiTags('complaints-admin')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.OWNER, UserRole.MANAGER, UserRole.CASHIER)
@Controller('admin/complaints')
export class ComplaintsAdminController {
  constructor(private complaints: ComplaintsService) {}

  @Get()
  list(
    @CurrentUser() user: JwtPayload,
    @Query() query: ListComplaintsQuery,
  ) {
    return this.complaints.listForRestaurant(
      requireRestaurantId(user),
      query.status,
    );
  }

  @Patch(':id')
  update(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
    @Body() dto: UpdateComplaintDto,
  ) {
    return this.complaints.update(user, id, dto);
  }
}
