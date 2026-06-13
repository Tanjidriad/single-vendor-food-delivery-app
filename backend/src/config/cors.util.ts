/** Parse comma-separated CORS_ORIGINS into a trimmed list. */
export function parseCorsOrigins(raw?: string): string[] {
  return (raw ?? '*')
    .split(',')
    .map((o) => o.trim())
    .filter(Boolean);
}

/** Socket.IO / Express CORS `origin` value from a parsed allowlist. */
export function corsOriginSetting(
  origins: string[],
): boolean | string[] {
  return origins.includes('*') ? true : origins;
}
