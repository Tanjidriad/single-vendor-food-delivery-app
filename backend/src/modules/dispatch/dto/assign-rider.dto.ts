import { ApiProperty } from '@nestjs/swagger';
import { IsUUID } from 'class-validator';

export class AssignRiderDto {
  @ApiProperty()
  @IsUUID()
  riderProfileId: string;
}
