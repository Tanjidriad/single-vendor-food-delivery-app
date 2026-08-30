/** Normalize a Bangladesh mobile number to the E.164 form expected by Nest. */
export function toBangladeshE164(raw: string): string {
  const trimmed = raw.trim();
  const digits = trimmed.replace(/[^\d]/g, "");
  if (trimmed.startsWith("+")) return trimmed;
  if (digits.startsWith("880")) return `+${digits}`;
  if (digits.startsWith("0")) return `+88${digits}`;
  if (digits.startsWith("1")) return `+880${digits}`;
  return `+${digits}`;
}
