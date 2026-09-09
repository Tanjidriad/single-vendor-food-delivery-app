import { validateEnv } from './env.validation';

const baseDev = {
  NODE_ENV: 'development',
  DATABASE_URL: 'postgresql://localhost/db',
  JWT_ACCESS_SECRET: 'a'.repeat(32),
  JWT_REFRESH_SECRET: 'b'.repeat(32),
};

describe('validateEnv', () => {
  it('accepts valid development config', () => {
    expect(() => validateEnv(baseDev)).not.toThrow();
  });

  it('rejects wildcard CORS in production', () => {
    expect(() =>
      validateEnv({
        ...baseDev,
        NODE_ENV: 'production',
        CORS_ORIGINS: '*',
      }),
    ).toThrow(/CORS_ORIGINS/);
  });

  it('requires OTP delivery channel in production', () => {
    expect(() =>
      validateEnv({
        ...baseDev,
        NODE_ENV: 'production',
        CORS_ORIGINS: 'https://app.example.com',
      }),
    ).toThrow(/OTP delivery/);
  });

  it('accepts production config with rtcom.xyz SMS', () => {
    expect(() =>
      validateEnv({
        ...baseDev,
        NODE_ENV: 'production',
        CORS_ORIGINS: 'https://app.example.com',
        RTCOM_ACODE: 'acode-123',
        RTCOM_API_KEY: 'api-key-123',
        RTCOM_SENDER_ID: 'FoodDelivery',
        REDIS_URL: 'redis://localhost:6379',
        SENTRY_DSN: 'https://examplePublicKey@o0.ingest.sentry.io/0',
      }),
    ).not.toThrow();
  });
});
