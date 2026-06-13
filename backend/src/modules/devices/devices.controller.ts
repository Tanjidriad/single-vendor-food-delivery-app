import { Body, Controller, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { UserRole } from '@prisma/client';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { JwtPayload } from '../auth/interfaces/jwt-payload.interface';
import { DevicesService } from './devices.service';
import { RegisterDeviceDto } from './dto/register-device.dto';

@ApiTags('devices')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('devices')
export class DevicesController {
  constructor(private devicesService: DevicesService) {}

  @Post('register')
  @Roles(
    UserRole.CUSTOMER,
    UserRole.RIDER,
    UserRole.OWNER,
    UserRole.MANAGER,
    UserRole.CASHIER,
    UserRole.KITCHEN,
  )
  register(@CurrentUser() user: JwtPayload, @Body() dto: RegisterDeviceDto) {
    return this.devicesService.register(user.sub, dto);
  }

  @Post('refresh-token')
  @Roles(
    UserRole.CUSTOMER,
    UserRole.RIDER,
    UserRole.OWNER,
    UserRole.MANAGER,
    UserRole.CASHIER,
    UserRole.KITCHEN,
  )
  refresh(@CurrentUser() user: JwtPayload, @Body() dto: RegisterDeviceDto) {
    return this.devicesService.refreshToken(user.sub, dto);
  }
}
