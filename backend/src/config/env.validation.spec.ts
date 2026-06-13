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

  it('accepts production config with Twilio SMS', () => {
    expect(() =>
      validateEnv({
        ...baseDev,
        NODE_ENV: 'production',
        CORS_ORIGINS: 'https://app.example.com',
        TWILIO_ACCOUNT_SID: 'ACxxx',
        TWILIO_AUTH_TOKEN: 'token',
        TWILIO_FROM_NUMBER: '+15551234567',
      }),
    ).not.toThrow();
  });
});
