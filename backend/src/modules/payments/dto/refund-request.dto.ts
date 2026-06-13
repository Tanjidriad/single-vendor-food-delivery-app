import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { RefundRequestStatus } from '@prisma/client';
import { IsEnum, IsNumber, IsOptional, IsString, IsUUID, Min } from 'class-validator';

export class CreateRefundRequestDto {
  @ApiProperty()
  @IsUUID()
  orderId!: string;

  @ApiProperty()
  @IsNumber()
  @Min(0.01)
  amount!: number;

  @ApiProperty()
  @IsString()
  reason!: string;
}

export class UpdateRefundRequestDto {
  @ApiProperty({ enum: RefundRequestStatus })
  @IsEnum(RefundRequestStatus)
  status!: RefundRequestStatus;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  adminNote?: string;

  @ApiPropertyOptional({ description: 'Manual bKash refund transaction reference' })
  @IsOptional()
  @IsString()
  gatewayRef?: string;
}
