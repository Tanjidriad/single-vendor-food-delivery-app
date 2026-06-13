import { IsString } from 'class-validator';

export class ExecutePaymentDto {
  @IsString()
  paymentId: string;
}
