import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsString, Length, IsOptional } from 'class-validator';

export class VerifyDeliveryDto {
  @ApiProperty({ example: '1234' })
  @IsString()
  @Length(4, 6)
  otp: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  dropoffPhotoUrl?: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  pickupExperience?: string;
}
