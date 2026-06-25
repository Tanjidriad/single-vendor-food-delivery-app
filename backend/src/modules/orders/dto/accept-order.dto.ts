import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsInt, IsOptional, Max, Min } from 'class-validator';

export class AcceptOrderDto {
  @ApiPropertyOptional({ description: 'Estimated preparation time in minutes' })
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(120)
  prepMinutes?: number;
}
