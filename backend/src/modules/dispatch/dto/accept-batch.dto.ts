import { ApiProperty } from '@nestjs/swagger';
import { ArrayMaxSize, ArrayMinSize, IsArray, IsUUID } from 'class-validator';

/// Body for POST /rider/assignments/accept-batch — the rider accepts several of
/// their pending (NOTIFIED) offers at once. Bounded so a single request can't
/// fan out unboundedly.
export class AcceptBatchDto {
  @ApiProperty({ type: [String] })
  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(20)
  @IsUUID('all', { each: true })
  assignmentIds: string[];
}
