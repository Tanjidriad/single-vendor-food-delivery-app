import { Controller, Delete, Get, Param, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { UserRole } from '@prisma/client';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { JwtPayload } from '../auth/interfaces/jwt-payload.interface';
import { FavoritesService } from './favorites.service';

@ApiTags('favorites')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.CUSTOMER)
@Controller('favorites')
export class FavoritesController {
  constructor(private favorites: FavoritesService) {}

  @Get()
  list(@CurrentUser() user: JwtPayload) {
    return this.favorites.list(user.sub);
  }

  @Post(':menuItemId')
  add(@CurrentUser() user: JwtPayload, @Param('menuItemId') menuItemId: string) {
    return this.favorites.add(user.sub, menuItemId);
  }

  @Delete(':menuItemId')
  remove(@CurrentUser() user: JwtPayload, @Param('menuItemId') menuItemId: string) {
    return this.favorites.remove(user.sub, menuItemId);
  }
}
