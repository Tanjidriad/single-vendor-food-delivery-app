import { IsBoolean, IsInt, IsNumber, IsOptional, IsString, Min } from 'class-validator';

export class UpdateSettingsDto {
  @IsOptional()
  @IsNumber()
  @Min(0)
  taxRatePercent?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  packagingFee?: number;

  @IsOptional()
  @IsString()
  currency?: string;

  @IsOptional()
  @IsNumber()
  @Min(0)
  minOrderAmount?: number;

  @IsOptional()
  @IsBoolean()
  autoAcceptOrders?: boolean;

  @IsOptional()
  @IsInt()
  @Min(1)
  defaultPrepMinutes?: number;

  @IsOptional()
  @IsInt()
  @Min(10)
  assignmentTimeoutSec?: number;

  @IsOptional()
  @IsInt()
  @Min(1)
  slaAcceptSeconds?: number;

  @IsOptional()
  @IsInt()
  @Min(1)
  slaPrepSeconds?: number;

  @IsOptional()
  @IsInt()
  @Min(1)
  slaPickupWaitSeconds?: number;

  @IsOptional()
  @IsBoolean()
  showTestOrdersInKitchen?: boolean;
}
