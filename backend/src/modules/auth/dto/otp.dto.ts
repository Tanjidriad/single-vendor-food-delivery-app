import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsEmail, IsIn, IsOptional, IsPhoneNumber, IsString, Length } from 'class-validator';

export class SendOtpDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsPhoneNumber()
  phone?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsEmail()
  email?: string;

  @ApiProperty({ enum: ['LOGIN', 'RESET_PASSWORD', 'VERIFY_PHONE'] })
  @IsIn(['LOGIN', 'RESET_PASSWORD', 'VERIFY_PHONE'])
  purpose: 'LOGIN' | 'RESET_PASSWORD' | 'VERIFY_PHONE';
}

export class VerifyOtpDto extends SendOtpDto {
  @ApiProperty()
  @IsString()
  @Length(6, 6)
  code: string;
}

export class ResetPasswordDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsPhoneNumber()
  phone?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsEmail()
  email?: string;

  @ApiProperty()
  @IsString()
  @Length(6, 6)
  code: string;

  @ApiProperty()
  @IsString()
  @Length(8, 64)
  newPassword: string;
}
