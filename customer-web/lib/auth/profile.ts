import type { AuthUser } from "@/types";

interface RawAuthProfile extends Partial<AuthUser> {
  sub?: string;
  customerProfile?: { fullName?: string | null } | null;
}

export function normalizeAuthProfile(
  value: unknown,
  fallback?: AuthUser | null
): AuthUser {
  const raw = (value ?? {}) as RawAuthProfile;
  return {
    id: raw.id ?? raw.sub ?? fallback?.id ?? "",
    email: raw.email ?? fallback?.email ?? null,
    phone: raw.phone ?? fallback?.phone ?? null,
    role: raw.role ?? fallback?.role ?? "CUSTOMER",
    fullName:
      raw.fullName ??
      raw.customerProfile?.fullName ??
      fallback?.fullName ??
      null,
  };
}
