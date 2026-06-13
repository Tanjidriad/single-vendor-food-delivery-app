import { IsNotEmpty, IsOptional, IsString } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class DispatchExternalDto {
  @ApiProperty({ example: 'Pathao Parcel', description: 'Name of the third-party courier service' })
  @IsString()
  @IsNotEmpty()
  deliveryService: string;

  @ApiProperty({ example: 'PATHAO-987123', description: 'Tracking / consignment ID from the courier' })
  @IsString()
  @IsNotEmpty()
  trackingId: string;

  @ApiPropertyOptional({ example: 'https://merchant.pathao.com/tracking/PATHAO-987123', description: 'Direct tracking page URL (optional)' })
  @IsString()
  @IsOptional()
  trackingUrl?: string;
}
