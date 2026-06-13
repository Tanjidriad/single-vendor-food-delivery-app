import { randomInt } from 'crypto';

/**
 * Cryptographically secure 4-digit delivery OTP. Uses crypto.randomInt (CSPRNG)
 * rather than Math.random, which is predictable and brute-forceable.
 */
export function generateDeliveryOtp(): string {
  return String(randomInt(1000, 10000));
}
