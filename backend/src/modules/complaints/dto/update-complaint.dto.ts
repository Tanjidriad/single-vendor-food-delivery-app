import { ApiPropertyOptional } from '@nestjs/swagger';
import { ComplaintStatus } from '../../../common/enums/complaint.enum';
import { IsEnum, IsNumber, IsOptional, IsString, Min } from 'class-validator';

export class UpdateComplaintDto {
  @ApiPropertyOptional({ enum: ComplaintStatus })
  @IsOptional()
  @IsEnum(ComplaintStatus)
  status?: ComplaintStatus;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  staffNote?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsNumber()
  @Min(0)
  refundAmount?: number;
}
