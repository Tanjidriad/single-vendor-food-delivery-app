const TRUSTED_PAYMENT_HOSTS = ["bka.sh", "bkash.com"] as const;

export function isTrustedPaymentUrl(value: string): boolean {
  try {
    const url = new URL(value);
    if (url.protocol !== "https:") return false;
    return TRUSTED_PAYMENT_HOSTS.some(
      (host) => url.hostname === host || url.hostname.endsWith(`.${host}`)
    );
  } catch {
    return false;
  }
}
