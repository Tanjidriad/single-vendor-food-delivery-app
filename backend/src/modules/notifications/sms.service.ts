import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { retryFetch } from '../../common/utils/retry-fetch.util';

@Injectable()
export class SmsService implements OnModuleInit {
  private readonly logger = new Logger(SmsService.name);
  private enabled = false;
  private acode = '';
  private apiKey = '';
  private senderId = '';

  constructor(private config: ConfigService) {}

  onModuleInit() {
    const acode    = this.config.get<string>('sms.rtcomAcode')?.trim();
    const apiKey   = this.config.get<string>('sms.rtcomApiKey')?.trim();
    const senderId = this.config.get<string>('sms.rtcomSenderId')?.trim();

    if (acode && apiKey && senderId) {
      this.acode    = acode;
      this.apiKey   = apiKey;
      this.senderId = senderId;
      this.enabled  = true;
      this.logger.log('rtcom.xyz SMS provider configured');
      return;
    }

    const nodeEnv = this.config.get<string>('nodeEnv') ?? 'production';
    if (nodeEnv === 'production') {
      this.logger.warn(
        'SMS not configured (set RTCOM_ACODE, RTCOM_API_KEY, RTCOM_SENDER_ID). Phone OTP will fail in production.',
      );
    }
  }

  isEnabled(): boolean {
    return this.enabled;
  }

  async sendOtp(phone: string, code: string, expiryMinutes: number): Promise<boolean> {
    if (!this.enabled) {
      return false;
    }

    const msg = `Your FoodDelivery verification code is ${code}. Valid for ${expiryMinutes} minutes. Do not share this code.`;

    try {
      const response = await retryFetch('https://api.rtcom.xyz/onetomany', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        signal: AbortSignal.timeout(10_000),
        body: JSON.stringify({
          acode:           this.acode,
          api_key:         this.apiKey,
          senderid:        this.senderId,
          type:            'text',
          msg,
          contacts:        phone,
          transactionType: 'T',
          contentID:       '',
        }),
      });

      const json = await response.json() as { response?: { code?: number; message?: string } };
      if (json?.response?.code === 200) {
        this.logger.log(`SMS OTP sent to ${phone}`);
        return true;
      }

      this.logger.error(`rtcom SMS failed for ${phone}: ${json?.response?.message ?? 'unknown error'}`);
      return false;
    } catch (err) {
      this.logger.error(`rtcom SMS error for ${phone}`, err);
      return false;
    }
  }
}
