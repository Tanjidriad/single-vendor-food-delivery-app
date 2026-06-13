import { ApiProperty } from '@nestjs/swagger';
import { RiderDocumentType } from '@prisma/client';
import { IsEnum } from 'class-validator';

/// Body for POST /rider/documents (multipart). The file is sent as `file`;
/// this DTO carries the document `type` field.
export class UploadRiderDocumentDto {
  @ApiProperty({ enum: RiderDocumentType })
  @IsEnum(RiderDocumentType)
  type: RiderDocumentType;
}
