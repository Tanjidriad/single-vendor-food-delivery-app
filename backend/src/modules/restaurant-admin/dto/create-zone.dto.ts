import { IsBoolean, IsNumber, IsObject, IsOptional, IsString, Min } from 'class-validator';

export class CreateZoneDto {
  @IsString()
  name: string;

  @IsOptional()
  @IsObject()
  polygonGeo?: object;

  @IsOptional()
  @IsNumber()
  @Min(0)
  maxDistanceKm?: number;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}
