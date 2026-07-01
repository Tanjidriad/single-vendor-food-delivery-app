/**
 * Boot-time environment validation. Runs inside ConfigModule.forRoot({ validate }).
 *
 * Fails fast (process won't start) when required secrets are missing or too
 * weak, instead of booting and failing per-request later. No external deps —
 * plain checks so this can't itself break the boot.
 */
export function validateEnv(config: Record<string, unknown>) {
  const errors: string[] = [];

  const required = (key: string, minLength = 1) => {
    const value = config[key];
    if (typeof value !== 'string' || value.trim().length === 0) {
      errors.push(`${key} is required`);
      return;
    }
    if (value.length < minLength) {
      errors.push(`${key} must be at least ${minLength} characters`);
    }
  };

  required('DATABASE_URL');
  required('JWT_ACCESS_SECRET', 32);
  required('JWT_REFRESH_SECRET', 32);

  // In production, refuse insecure defaults that are safe only for local dev.
  const nodeEnv = (config.NODE_ENV as string) ?? 'production';
  if (nodeEnv === 'production') {
    const access = config.JWT_ACCESS_SECRET as string | undefined;
    const refresh = config.JWT_REFRESH_SECRET as string | undefined;
    const weakPatterns = ['change-me', 'dev-access-secret', 'dev-refresh-secret'];
    if (
      weakPatterns.some(
        (p) => access?.includes(p) || refresh?.includes(p),
      )
    ) {
      errors.push(
        'JWT secrets must be unique production values (remove dev/placeholder strings)',
      );
    }
    const cors = (config.CORS_ORIGINS as string | undefined)?.trim();
    if (!cors || cors === '*') {
      errors.push(
        'CORS_ORIGINS must be an explicit allowlist in production (wildcard "*" is not allowed with credentials)',
      );
    }

    const redisUrl = config.REDIS_URL as string | undefined;
    if (!redisUrl || redisUrl.trim().length === 0) {
      errors.push('REDIS_URL is required in production (rate-limiting, job queues)');
    }

    const sentryDsn = config.SENTRY_DSN as string | undefined;
    if (!sentryDsn || sentryDsn.trim().length === 0) {
      errors.push('SENTRY_DSN is required in production (error monitoring)');
    }

    const hasSms =
      typeof config.RTCOM_ACODE === 'string' &&
      config.RTCOM_ACODE.trim().length > 0 &&
      typeof config.RTCOM_API_KEY === 'string' &&
      config.RTCOM_API_KEY.trim().length > 0 &&
      typeof config.RTCOM_SENDER_ID === 'string' &&
      config.RTCOM_SENDER_ID.trim().length > 0;
    const hasEmailOtp =
      typeof config.RESEND_API_KEY === 'string' &&
      config.RESEND_API_KEY.trim().length > 0;

    if (!hasSms && !hasEmailOtp) {
      errors.push(
        'Configure OTP delivery in production: RTCOM_ACODE + RTCOM_API_KEY + RTCOM_SENDER_ID (SMS) and/or RESEND_API_KEY (email)',
      );
    }
  }

  if (errors.length) {
    throw new Error(
      `Invalid environment configuration:\n  - ${errors.join('\n  - ')}`,
    );
  }

  return config;
}
