import { Body, Controller, Get, Post, Query } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { IsNumber, IsString, IsUUID } from 'class-validator';
import { Public } from '../../common/decorators/public.decorator';
import { CouponsService } from './coupons.service';

class ValidateCouponDto {
  @IsUUID()
  restaurantId: string;

  @IsString()
  code: string;

  @IsNumber()
  subtotal: number;
}

@ApiTags('coupons')
@Controller('coupons')
export class CouponsController {
  constructor(private coupons: CouponsService) {}

  /** Public: lists active, non-expired coupons for a restaurant */
  @Public()
  @Get('public')
  listPublic(@Query('restaurantId') restaurantId: string) {
    return this.coupons.listPublic(restaurantId);
  }

  @Public()
  @Post('validate')
  validate(@Body() dto: ValidateCouponDto) {
    return this.coupons.validate(dto.restaurantId, dto.code, dto.subtotal);
  }
}
