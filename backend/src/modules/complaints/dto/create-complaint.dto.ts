import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { ComplaintType } from '../../../common/enums/complaint.enum';
import { IsEnum, IsNumber, IsOptional, IsString, IsUUID, Min, MinLength } from 'class-validator';

export class CreateComplaintDto {
  @ApiProperty({ format: 'uuid' })
  @IsUUID()
  orderId: string;

  @ApiProperty({ enum: ComplaintType })
  @IsEnum(ComplaintType)
  type: ComplaintType;

  @ApiProperty()
  @IsString()
  @MinLength(3)
  subject: string;

  @ApiProperty()
  @IsString()
  @MinLength(10)
  description: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  @Min(0)
  refundAmount?: number;
}
