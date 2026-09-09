export type PaymentGatewayId = 'bkash' | 'sslcommerz';

export interface CreatePaymentInput {
  amount: number;
  merchantInvoiceNumber: string;
  payerReference?: string;
  callbackUrl: string;
}

export interface CreatePaymentResult {
  paymentId: string;
  checkoutUrl: string;
  raw?: unknown;
}

export interface ExecutePaymentResult {
  success: boolean;
  transactionId?: string;
  transactionStatus?: string;
  /** Amount the gateway actually captured, for server-side verification. */
  amount?: string;
  raw?: unknown;
}

export interface QueryPaymentResult {
  success: boolean;
  transactionId?: string;
  transactionStatus?: string;
  /** Amount the gateway actually captured, for server-side verification. */
  amount?: string;
  raw?: unknown;
}

export interface RefundPaymentResult {
  success: boolean;
  refundTrxId?: string;
  errorMessage?: string;
  raw?: unknown;
}

export interface PaymentGatewayProvider {
  readonly id: PaymentGatewayId;
  createPayment(input: CreatePaymentInput): Promise<CreatePaymentResult>;
  executePayment(paymentId: string): Promise<ExecutePaymentResult>;
  queryPayment(paymentId: string): Promise<QueryPaymentResult>;
  refundPayment?(
    transactionId: string,
    amount: number,
  ): Promise<RefundPaymentResult>;
}

export const PAYMENT_GATEWAY = Symbol('PAYMENT_GATEWAY');
