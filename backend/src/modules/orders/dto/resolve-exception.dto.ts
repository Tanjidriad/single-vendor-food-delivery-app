import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsOptional, IsString } from 'class-validator';

export enum ResolveExceptionAction {
  REASSIGN = 'REASSIGN',
  CANCEL_REFUND = 'CANCEL_REFUND',
  CLONE_REORDER = 'CLONE_REORDER',
  RESOLVED_NO_REFUND = 'RESOLVED_NO_REFUND',
}

export class ResolveExceptionDto {
  @ApiProperty({ enum: ResolveExceptionAction })
  @IsEnum(ResolveExceptionAction)
  action!: ResolveExceptionAction;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  note?: string;
}
