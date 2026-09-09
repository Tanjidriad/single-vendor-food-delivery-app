import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, MaxLength } from 'class-validator';

export class RejectOrderDto {
  @ApiPropertyOptional({ description: 'Reason for rejecting the order' })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  note?: string;
}
