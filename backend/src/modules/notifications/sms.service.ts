import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

/**
 * SMS delivery for OTP and transactional messages.
 * Twilio is the default provider; map keys can be swapped later without touching auth.
 */
@Injectable()
export class SmsService implements OnModuleInit {
  private readonly logger = new Logger(SmsService.name);
  private enabled = false;
  private accountSid = '';
  private authToken = '';
  private fromNumber = '';

  constructor(private config: ConfigService) {}

  onModuleInit() {
    const accountSid = this.config.get<string>('sms.twilioAccountSid')?.trim();
    const authToken = this.config.get<string>('sms.twilioAuthToken')?.trim();
    const fromNumber = this.config.get<string>('sms.twilioFromNumber')?.trim();

    if (accountSid && authToken && fromNumber) {
      this.accountSid = accountSid;
      this.authToken = authToken;
      this.fromNumber = fromNumber;
      this.enabled = true;
      this.logger.log('Twilio SMS provider configured');
      return;
    }

    const nodeEnv = this.config.get<string>('nodeEnv') ?? 'production';
    if (nodeEnv === 'production') {
      this.logger.warn(
        'SMS not configured (set TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, TWILIO_FROM_NUMBER). Phone OTP will fail in production.',
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

    const body = `Your FoodDelivery verification code is ${code}. Valid for ${expiryMinutes} minutes. Do not share this code.`;

    try {
      const url = `https://api.twilio.com/2010-04-01/Accounts/${this.accountSid}/Messages.json`;
      const auth = Buffer.from(`${this.accountSid}:${this.authToken}`).toString(
        'base64',
      );
      const params = new URLSearchParams({
        To: phone,
        From: this.fromNumber,
        Body: body,
      });

      const response = await fetch(url, {
        method: 'POST',
        headers: {
          Authorization: `Basic ${auth}`,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: params.toString(),
      });

      if (!response.ok) {
        const text = await response.text();
        this.logger.error(`Twilio SMS failed (${response.status}): ${text}`);
        return false;
      }

      this.logger.log(`SMS OTP sent to ${phone}`);
      return true;
    } catch (err) {
      this.logger.error(`Twilio SMS error for ${phone}`, err);
      return false;
    }
  }
}
