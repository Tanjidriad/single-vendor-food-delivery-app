import { Controller, Get, Param, Query } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { Public } from '../../common/decorators/public.decorator';
import { MenuFilterDto } from './dto/menu-filter.dto';
import { MenuService } from './menu.service';

@ApiTags('menu')
@Controller('menu')
export class MenuController {
  constructor(private menuService: MenuService) {}

  @Public()
  @Get('restaurant/:restaurantId')
  getMenu(@Param('restaurantId') restaurantId: string) {
    return this.menuService.getPublicMenu(restaurantId);
  }

  @Public()
  @Get('restaurant/:restaurantId/featured')
  featured(@Param('restaurantId') restaurantId: string) {
    return this.menuService.getFeatured(restaurantId);
  }

  @Public()
  @Get('items/:itemId')
  getItem(@Param('itemId') itemId: string) {
    return this.menuService.getItem(itemId);
  }

  @Public()
  @Get('restaurant/:restaurantId/banners')
  banners(@Param('restaurantId') restaurantId: string) {
    return this.menuService.getBanners(restaurantId);
  }

  @Public()
  @Get('restaurant/:restaurantId/filter')
  filter(
    @Param('restaurantId') restaurantId: string,
    @Query() query: MenuFilterDto,
  ) {
    return this.menuService.filter(restaurantId, query);
  }

  @Public()
  @Get('restaurant/:restaurantId/search')
  search(
    @Param('restaurantId') restaurantId: string,
    @Query('q') q: string,
  ) {
    return this.menuService.search(restaurantId, q ?? '');
  }
}
