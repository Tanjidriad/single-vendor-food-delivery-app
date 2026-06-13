import { Body, Controller, Get, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { UserRole } from '@prisma/client';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { JwtPayload } from '../auth/interfaces/jwt-payload.interface';
import { ComplaintsService } from './complaints.service';
import { CreateComplaintDto } from './dto/create-complaint.dto';

@ApiTags('complaints')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.CUSTOMER)
@Controller('complaints')
export class ComplaintsController {
  constructor(private complaints: ComplaintsService) {}

  @Post()
  create(@CurrentUser() user: JwtPayload, @Body() dto: CreateComplaintDto) {
    return this.complaints.create(user.sub, dto);
  }

  @Get('me')
  listMine(@CurrentUser() user: JwtPayload) {
    return this.complaints.listMine(user.sub);
  }
}
