import { ApiProperty } from '@nestjs/swagger';
import { IsNumber, IsOptional, IsString, IsUUID } from 'class-validator';

export class DeliveryFeeQuoteDto {
  @ApiProperty()
  @IsUUID()
  restaurantId: string;

  @ApiProperty()
  @IsNumber()
  deliveryLat: number;

  @ApiProperty()
  @IsNumber()
  deliveryLng: number;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsNumber()
  subtotal?: number;
}
