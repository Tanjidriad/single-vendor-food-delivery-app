import { parseCorsOrigins } from './cors.util';

export default () => ({
  // Default to production when unset, so prod-sensitive gates (OTP leak, dev
  // endpoints, Swagger) fail safe. Local dev sets NODE_ENV=development in .env.
  nodeEnv: process.env.NODE_ENV ?? 'production',
  port: parseInt(process.env.PORT ?? '3000', 10),
  /** Bind address — use 0.0.0.0 so phones on the same Wi‑Fi can reach the API. */
  host: process.env.HOST ?? '0.0.0.0',
  apiPrefix: process.env.API_PREFIX ?? 'api/v1',
  /**
   * Express `trust proxy` setting. Behind a load balancer / reverse proxy the
   * real client IP is in X-Forwarded-For; without this, per-IP rate limiting
   * either buckets everyone together or is XFF-spoofable. Defaults to trusting
   * one hop in production, off in dev. Set TRUST_PROXY to a hop count, a boolean,
   * or an Express trust-proxy expression (e.g. "loopback").
   */
  trustProxy:
    process.env.TRUST_PROXY ??
    ((process.env.NODE_ENV ?? 'production') === 'production'
      ? '1'
      : undefined),
  databaseUrl: process.env.DATABASE_URL,
  redisUrl: process.env.REDIS_URL,
  jwt: {
    accessSecret: process.env.JWT_ACCESS_SECRET,
    refreshSecret: process.env.JWT_REFRESH_SECRET,
    accessExpiresIn: process.env.JWT_ACCESS_EXPIRES_IN ?? '15m',
    refreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN ?? '7d',
  },
  corsOrigins: parseCorsOrigins(process.env.CORS_ORIGINS),
  googleMapsApiKey: process.env.GOOGLE_MAPS_API_KEY,
  mapboxAccessToken: process.env.MAPBOX_ACCESS_TOKEN,
  restaurant: {
    lat: parseFloat(process.env.RESTAURANT_LAT ?? '23.8103'),
    lng: parseFloat(process.env.RESTAURANT_LNG ?? '90.4125'),
  },
  assignmentTimeoutSeconds: parseInt(
    process.env.ASSIGNMENT_TIMEOUT_SECONDS ?? '45',
    10,
  ),
  cloudinary: {
    cloudName: process.env.CLOUDINARY_CLOUD_NAME,
    apiKey: process.env.CLOUDINARY_API_KEY,
    apiSecret: process.env.CLOUDINARY_API_SECRET,
  },
  fcm: {
    projectId: process.env.FCM_PROJECT_ID,
    clientEmail: process.env.FCM_CLIENT_EMAIL,
    privateKey: process.env.FCM_PRIVATE_KEY?.replace(/\\n/g, '\n'),
  },
  // Client app version gating. The customer app calls /app/config on launch and
  // blocks itself when its build is below minSupportedVersion, so a broken old
  // client can be forced to upgrade without a server-side allowlist.
  appVersioning: {
    minSupportedVersion: process.env.MIN_APP_VERSION ?? '1.0.0',
    latestVersion: process.env.LATEST_APP_VERSION ?? '1.0.0',
    androidUpdateUrl: process.env.ANDROID_UPDATE_URL ?? '',
    iosUpdateUrl: process.env.IOS_UPDATE_URL ?? '',
  },
  otpExpiryMinutes: parseInt(process.env.OTP_EXPIRY_MINUTES ?? '10', 10),
  resendApiKey: process.env.RESEND_API_KEY,
  sentryDsn: process.env.SENTRY_DSN,
  sms: {
    twilioAccountSid: process.env.TWILIO_ACCOUNT_SID,
    twilioAuthToken: process.env.TWILIO_AUTH_TOKEN,
    twilioFromNumber: process.env.TWILIO_FROM_NUMBER,
  },
  paymentGateway: (process.env.PAYMENT_GATEWAY ?? 'bkash') as 'bkash' | 'sslcommerz',
  bkash: {
    sandbox: process.env.BKASH_SANDBOX !== 'false',
    baseUrl:
      process.env.BKASH_BASE_URL ??
      (process.env.BKASH_SANDBOX === 'false'
        ? 'https://tokenized.pay.bka.sh/v1.2.0-beta'
        : 'https://tokenized.sandbox.bka.sh/v1.2.0-beta'),
    appKey: process.env.BKASH_APP_KEY,
    appSecret: process.env.BKASH_APP_SECRET,
    username: process.env.BKASH_USERNAME,
    password: process.env.BKASH_PASSWORD,
    callbackUrl: process.env.BKASH_CALLBACK_URL,
  },
});
