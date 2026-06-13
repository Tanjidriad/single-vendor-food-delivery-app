import { IsBoolean, IsOptional, IsString, Matches } from 'class-validator';

export class UpdateOperatingHourDto {
  @IsString()
  @Matches(/^\d{2}:\d{2}$/, { message: 'openTime must be in HH:MM format' })
  openTime: string;

  @IsString()
  @Matches(/^\d{2}:\d{2}$/, { message: 'closeTime must be in HH:MM format' })
  closeTime: string;

  @IsOptional()
  @IsBoolean()
  isClosed?: boolean;
}
