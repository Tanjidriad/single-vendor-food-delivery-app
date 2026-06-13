import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { UserRole } from '@prisma/client';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { requireRestaurantId } from '../../common/utils/staff-restaurant.util';
import { JwtPayload } from '../auth/interfaces/jwt-payload.interface';
import { MenuAdminService } from './menu-admin.service';

@ApiTags('menu-admin')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.OWNER, UserRole.MANAGER, UserRole.CASHIER, UserRole.KITCHEN, UserRole.ADMIN)
@Controller('admin/menu')
export class MenuAdminController {
  constructor(private menuAdmin: MenuAdminService) {}

  @Get()
  getFullMenu(@CurrentUser() user: JwtPayload) {
    return this.menuAdmin.getFullMenu(requireRestaurantId(user));
  }

  @Post('categories')
  createCategory(@CurrentUser() user: JwtPayload, @Body() body: Record<string, unknown>) {
    return this.menuAdmin.createCategory(requireRestaurantId(user), body);
  }

  @Patch('categories/:id')
  updateCategory(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
    @Body() body: Record<string, unknown>,
  ) {
    return this.menuAdmin.updateCategory(requireRestaurantId(user), id, body);
  }

  @Delete('categories/:id')
  deleteCategory(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    return this.menuAdmin.deleteCategory(requireRestaurantId(user), id);
  }

  @Post('items')
  createItem(@CurrentUser() user: JwtPayload, @Body() body: Record<string, unknown>) {
    return this.menuAdmin.createItem(requireRestaurantId(user), body);
  }

  @Patch('items/:id')
  updateItem(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
    @Body() body: Record<string, unknown>,
  ) {
    return this.menuAdmin.updateItem(requireRestaurantId(user), id, body);
  }

  @Delete('items/:id')
  deleteItem(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    return this.menuAdmin.deleteItem(requireRestaurantId(user), id);
  }

  @Get('addons')
  getAddons(@CurrentUser() user: JwtPayload) {
    return this.menuAdmin.getAddons(requireRestaurantId(user));
  }

  @Post('addons')
  createAddon(@CurrentUser() user: JwtPayload, @Body() body: Record<string, unknown>) {
    return this.menuAdmin.createAddon(requireRestaurantId(user), body);
  }

  @Patch('addons/:id')
  updateAddon(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
    @Body() body: Record<string, unknown>,
  ) {
    return this.menuAdmin.updateAddon(requireRestaurantId(user), id, body);
  }

  @Delete('addons/:id')
  deleteAddon(@CurrentUser() user: JwtPayload, @Param('id') id: string) {
    return this.menuAdmin.deleteAddon(requireRestaurantId(user), id);
  }

  @Post('items/:itemId/addons/:addonId')
  linkAddon(@Param('itemId') itemId: string, @Param('addonId') addonId: string) {
    return this.menuAdmin.linkAddon(itemId, addonId);
  }

  @Delete('items/:itemId/addons/:addonId')
  unlinkAddon(@Param('itemId') itemId: string, @Param('addonId') addonId: string) {
    return this.menuAdmin.unlinkAddon(itemId, addonId);
  }
}
