import { Body, Controller, Get, Param, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { UserRole } from '@prisma/client';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { JwtPayload } from '../auth/interfaces/jwt-payload.interface';
import { CreateMessageDto } from './dto/create-message.dto';
import { MessagesService } from './messages.service';

@ApiTags('messages')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('orders/:orderId/messages')
export class MessagesController {
  constructor(private messages: MessagesService) {}

  @Get()
  @Roles(
    UserRole.CUSTOMER,
    UserRole.RIDER,
    UserRole.OWNER,
    UserRole.MANAGER,
    UserRole.CASHIER,
    UserRole.ADMIN,
  )
  list(@CurrentUser() user: JwtPayload, @Param('orderId') orderId: string) {
    return this.messages.list(user, orderId);
  }

  @Post()
  @Roles(
    UserRole.CUSTOMER,
    UserRole.RIDER,
    UserRole.OWNER,
    UserRole.MANAGER,
    UserRole.CASHIER,
    UserRole.ADMIN,
  )
  create(
    @CurrentUser() user: JwtPayload,
    @Param('orderId') orderId: string,
    @Body() dto: CreateMessageDto,
  ) {
    return this.messages.create(user, orderId, dto.body);
  }
}
