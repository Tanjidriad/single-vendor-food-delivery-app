import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { DeliveryExceptionReason } from '@prisma/client';
import { IsEnum, IsNumber, IsOptional, IsString, IsUrl } from 'class-validator';

export class DeliveryExceptionDto {
  @ApiProperty({ enum: DeliveryExceptionReason })
  @IsEnum(DeliveryExceptionReason)
  reason!: DeliveryExceptionReason;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  note?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsUrl()
  photoUrl?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  latitude?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  longitude?: number;

  @ApiPropertyOptional({ description: 'True when rider has picked up food and is returning it' })
  @IsOptional()
  foodReturned?: boolean;
}
