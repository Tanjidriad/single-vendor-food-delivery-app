import {
  Injectable,
  Logger,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  CreatePaymentInput,
  CreatePaymentResult,
  ExecutePaymentResult,
  PaymentGatewayProvider,
  QueryPaymentResult,
  RefundPaymentResult,
} from './payment-gateway.interface';

interface BkashTokenCache {
  idToken: string;
  expiresAt: number;
}

@Injectable()
export class BkashProvider implements PaymentGatewayProvider {
  readonly id = 'bkash' as const;

  private readonly logger = new Logger(BkashProvider.name);
  private tokenCache: BkashTokenCache | null = null;

  constructor(private config: ConfigService) {}

  private get baseUrl(): string {
    return (
      this.config.get<string>('bkash.baseUrl') ??
      'https://tokenized.sandbox.bka.sh/v1.2.0-beta'
    );
  }

  private get appKey(): string {
    const key = this.config.get<string>('bkash.appKey')?.trim();
    if (!key) {
      throw new ServiceUnavailableException('bKash App Key is not configured');
    }
    return key;
  }

  private get appSecret(): string {
    const secret = this.config.get<string>('bkash.appSecret')?.trim();
    if (!secret) {
      throw new ServiceUnavailableException('bKash App Secret is not configured');
    }
    return secret;
  }

  private get username(): string {
    const value = this.config.get<string>('bkash.username')?.trim();
    if (!value) {
      throw new ServiceUnavailableException('bKash username is not configured');
    }
    return value;
  }

  private get password(): string {
    const value = this.config.get<string>('bkash.password')?.trim();
    if (!value) {
      throw new ServiceUnavailableException('bKash password is not configured');
    }
    return value;
  }

  async createPayment(input: CreatePaymentInput): Promise<CreatePaymentResult> {
    const token = await this.grantToken();
    const body = {
      mode: '0011',
      payerReference: input.payerReference ?? 'customer',
      callbackURL: input.callbackUrl,
      amount: input.amount.toFixed(2),
      currency: 'BDT',
      intent: 'sale',
      merchantInvoiceNumber: input.merchantInvoiceNumber,
    };

    const data = await this.post<{
      statusCode?: string;
      statusMessage?: string;
      paymentID?: string;
      bkashURL?: string;
    }>('/tokenized/checkout/create', body, token);

    if (data.statusCode !== '0000' || !data.paymentID || !data.bkashURL) {
      this.logger.error(`bKash create failed: ${data.statusMessage ?? 'unknown'}`);
      throw new ServiceUnavailableException(
        data.statusMessage ?? 'bKash payment creation failed',
      );
    }

    return {
      paymentId: data.paymentID,
      checkoutUrl: data.bkashURL,
      raw: data,
    };
  }

  async executePayment(paymentId: string): Promise<ExecutePaymentResult> {
    const token = await this.grantToken();
    const data = await this.post<{
      statusCode?: string;
      statusMessage?: string;
      transactionStatus?: string;
      trxID?: string;
    }>('/tokenized/checkout/execute', { paymentID: paymentId }, token);

    const success =
      data.statusCode === '0000' && data.transactionStatus === 'Completed';

    return {
      success,
      transactionId: data.trxID,
      transactionStatus: data.transactionStatus,
      raw: data,
    };
  }

  async refundPayment(
    transactionId: string,
    amount: number,
  ): Promise<RefundPaymentResult> {
    const token = await this.grantToken();
    const data = await this.post<{
      statusCode?: string;
      statusMessage?: string;
      refundTrxID?: string;
    }>(
      '/tokenized/checkout/payment/refund',
      {
        paymentID: transactionId,
        amount: amount.toFixed(2),
        trxID: transactionId,
        sku: 'refund',
        reason: 'Delivery exception refund',
      },
      token,
    );

    const success = data.statusCode === '0000';
    return {
      success,
      refundTrxId: data.refundTrxID,
      errorMessage: success ? undefined : data.statusMessage,
      raw: data,
    };
  }

  async queryPayment(paymentId: string): Promise<QueryPaymentResult> {
    const token = await this.grantToken();
    const data = await this.post<{
      statusCode?: string;
      statusMessage?: string;
      transactionStatus?: string;
      trxID?: string;
    }>('/tokenized/checkout/payment/status', { paymentID: paymentId }, token);

    const success =
      data.statusCode === '0000' && data.transactionStatus === 'Completed';

    return {
      success,
      transactionId: data.trxID,
      transactionStatus: data.transactionStatus,
      raw: data,
    };
  }

  private async grantToken(): Promise<string> {
    const now = Date.now();
    if (this.tokenCache && this.tokenCache.expiresAt > now + 30_000) {
      return this.tokenCache.idToken;
    }

    const url = `${this.baseUrl}/tokenized/checkout/token/grant`;
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Accept: 'application/json',
        username: this.username,
        password: this.password,
      },
      body: JSON.stringify({
        app_key: this.appKey,
        app_secret: this.appSecret,
      }),
    });

    const data = (await response.json()) as {
      statusCode?: string;
      statusMessage?: string;
      id_token?: string;
      expires_in?: number | string;
    };

    if (!response.ok || data.statusCode !== '0000' || !data.id_token) {
      this.logger.error(
        `bKash grant token failed (${response.status}): ${data.statusMessage ?? 'unknown'}`,
      );
      throw new ServiceUnavailableException(
        data.statusMessage ?? 'bKash authentication failed',
      );
    }

    const expiresInSec =
      typeof data.expires_in === 'string'
        ? parseInt(data.expires_in, 10)
        : (data.expires_in ?? 3600);

    this.tokenCache = {
      idToken: data.id_token,
      expiresAt: now + expiresInSec * 1000,
    };

    return data.id_token;
  }

  private async post<T>(
    path: string,
    body: Record<string, unknown>,
    token: string,
  ): Promise<T> {
    const url = `${this.baseUrl}${path}`;
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Accept: 'application/json',
        authorization: token,
        'x-app-key': this.appKey,
      },
      body: JSON.stringify(body),
    });

    const data = (await response.json()) as T;
    if (!response.ok) {
      this.logger.error(`bKash ${path} HTTP ${response.status}`);
    }
    return data;
  }
}
