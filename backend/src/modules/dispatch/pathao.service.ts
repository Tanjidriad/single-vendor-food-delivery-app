import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { retryFetch } from '../../common/utils/retry-fetch.util';

interface PathaoTokenCache {
  accessToken: string;
  expiresAt: number; // epoch ms
}

export interface PathaoCreateOrderInput {
  /** Your internal order ID (stored as merchant_order_id) */
  merchantOrderId: string;
  recipientName: string;
  recipientPhone: string;
  recipientAddress: string;
  /** Amount in BDT the courier should collect (0 = prepaid / online payment) */
  amountToCollect: number;
  itemDescription?: string;
}

export interface PathaoOrderResult {
  consignmentId: string;
  merchantOrderId: string;
  orderStatus: string;
  deliveryFee: number;
}

@Injectable()
export class PathaoService {
  private readonly logger = new Logger(PathaoService.name);
  private tokenCache: PathaoTokenCache | null = null;

  constructor(private readonly config: ConfigService) {}

  // ─── Token management ──────────────────────────────────────────────────────

  private get baseUrl(): string {
    return this.config.get<string>('PATHAO_BASE_URL', 'https://courier-api-sandbox.pathao.com');
  }

  private get storeId(): number {
    const raw = this.config.get<string>('PATHAO_STORE_ID', '');
    const parsed = parseInt(raw, 10);
    if (isNaN(parsed)) {
      throw new Error('PATHAO_STORE_ID is not set or is not a valid number');
    }
    return parsed;
  }

  /**
   * Returns a valid Bearer token, fetching a fresh one if the cached one has
   * expired (or is about to expire within 60 seconds).
   */
  async getAccessToken(): Promise<string> {
    const now = Date.now();
    if (this.tokenCache && this.tokenCache.expiresAt > now + 60_000) {
      return this.tokenCache.accessToken;
    }

    this.logger.log('Fetching fresh Pathao access token…');

    const response = await fetch(`${this.baseUrl}/aladdin/api/v1/issue-token`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      signal: AbortSignal.timeout(10_000),
      body: JSON.stringify({
        client_id:     this.config.get('PATHAO_CLIENT_ID'),
        client_secret: this.config.get('PATHAO_CLIENT_SECRET'),
        username:      this.config.get('PATHAO_USERNAME'),
        password:      this.config.get('PATHAO_PASSWORD'),
        grant_type:    'password',
      }),
    });

    if (!response.ok) {
      const body = await response.text();
      throw new Error(`Pathao token request failed (HTTP ${response.status}): ${body}`);
    }

    const data = (await response.json()) as {
      access_token: string;
      expires_in: number;
    };

    if (!data.access_token) {
      throw new Error('Pathao token response missing access_token');
    }

    // Cache token; expires_in is in seconds
    this.tokenCache = {
      accessToken: data.access_token,
      expiresAt: now + data.expires_in * 1000,
    };

    this.logger.log(`Pathao token obtained (expires in ${data.expires_in}s)`);
    return this.tokenCache.accessToken;
  }

  // ─── Order creation ────────────────────────────────────────────────────────

  /**
   * Pathao requires the local BD format: 01XXXXXXXXX (11 digits, no +880 prefix).
   * Strips any leading +880 or 880 and ensures the number starts with 0.
   */
  private normalizePhone(phone: string): string {
    let cleaned = phone.replace(/[^\d]/g, ''); // digits only
    if (cleaned.startsWith('880')) {
      cleaned = '0' + cleaned.slice(3);
    }
    // If it's already 11 digits starting with 0, it's fine
    return cleaned || '01700000000'; // fallback prevents empty string
  }

  /**
   * Creates a parcel delivery request on Pathao and returns the consignment ID
   * (tracking number) that can be shown to the customer.
   */
  async createOrder(input: PathaoCreateOrderInput): Promise<PathaoOrderResult> {
    const token = await this.getAccessToken();

    const payload = {
      store_id:            this.storeId,
      merchant_order_id:   input.merchantOrderId,
      recipient_name:      input.recipientName,
      recipient_phone:     this.normalizePhone(input.recipientPhone),
      // Pathao requires at least 10 chars in recipient_address
      recipient_address:   input.recipientAddress.length >= 10
                             ? input.recipientAddress
                             : `${input.recipientAddress}, Dhaka, Bangladesh`,
      delivery_type:       48,  // 48 = normal delivery
      item_type:           2,   // 2 = parcel / food
      item_quantity:       1,
      item_weight:         '0.5',
      item_description:    input.itemDescription ?? 'Food order',
      amount_to_collect:   input.amountToCollect,
    };

    this.logger.log(`Creating Pathao order for merchant_order_id: ${input.merchantOrderId}`);

    const response = await retryFetch(`${this.baseUrl}/aladdin/api/v1/orders`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      signal: AbortSignal.timeout(15_000),
      body: JSON.stringify(payload),
    });

    if (!response.ok) {
      const body = await response.text();
      throw new Error(`Pathao order creation failed (HTTP ${response.status}): ${body}`);
    }

    const data = (await response.json()) as {
      data: {
        consignment_id: string;
        merchant_order_id: string;
        order_status: string;
        delivery_fee: number;
      };
    };

    const result: PathaoOrderResult = {
      consignmentId:   data.data.consignment_id,
      merchantOrderId: data.data.merchant_order_id,
      orderStatus:     data.data.order_status,
      deliveryFee:     data.data.delivery_fee,
    };

    this.logger.log(`Pathao order created — consignment_id: ${result.consignmentId}`);
    return result;
  }
}
