import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsNumber, IsOptional, IsString, Min } from 'class-validator';

export class SettleCodDto {
  @ApiPropertyOptional({
    description: 'Food portion remitted to restaurant; defaults to order food revenue',
  })
  @IsOptional()
  @IsNumber()
  @Min(0)
  foodAmountRemitted?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  note?: string;
}
