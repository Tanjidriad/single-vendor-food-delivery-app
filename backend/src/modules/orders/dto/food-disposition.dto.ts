import { ApiProperty } from '@nestjs/swagger';
import { FoodDisposition } from '@prisma/client';
import { IsEnum } from 'class-validator';

export class FoodDispositionDto {
  @ApiProperty({ enum: FoodDisposition })
  @IsEnum(FoodDisposition)
  disposition!: FoodDisposition;
}
