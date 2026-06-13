import { IsNumber, IsObject, IsOptional, Min } from 'class-validator';

export class UpdateFeeConfigDto {
  @IsOptional()
  @IsNumber()
  @Min(0)
  baseFee?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  perKmFee?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  peakHourSurcharge?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  freeDeliveryThreshold?: number;

  @IsOptional()
  @IsObject()
  peakHours?: object;

  @IsOptional()
  @IsNumber()
  @Min(0)
  maxDeliveryKm?: number;
}
