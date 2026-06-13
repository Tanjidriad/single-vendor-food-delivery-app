import { Body, Controller, Get, Post, Query } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { Public } from '../../common/decorators/public.decorator';
import { DeliveryFeeService } from './delivery-fee.service';
import { DeliveryFeeQuoteDto } from './dto/delivery-fee-quote.dto';
import { MapsService } from './maps.service';

@ApiTags('delivery-fee')
@Controller('delivery-fee')
export class DeliveryFeeController {
  constructor(
    private deliveryFeeService: DeliveryFeeService,
    private maps: MapsService,
  ) { }

  @Post('quote')
  quote(@Body() dto: DeliveryFeeQuoteDto) {
    return this.deliveryFeeService.quote(dto);
  }

  @Public()
  @Get('geocode')
  geocode(@Query('address') address: string) {
    return this.maps.geocode(address);
  }

  @Public()
  @Get('reverse-geocode')
  reverse(@Query('lat') lat: string, @Query('lng') lng: string) {
    return this.maps.reverseGeocode(parseFloat(lat), parseFloat(lng));
  }
}
