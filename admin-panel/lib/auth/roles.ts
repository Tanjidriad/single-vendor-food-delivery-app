import type { UserRole } from "@/types";

/** Roles permitted to sign into the admin panel (staff only — never customers/riders). */
export const STAFF_ROLES: UserRole[] = [
  "OWNER",
  "MANAGER",
  "ADMIN",
  "CASHIER",
  "KITCHEN",
];

export function isStaff(role?: UserRole | null): boolean {
  return !!role && STAFF_ROLES.includes(role);
}

/** Platform super-admin — gates the future multi-restaurant view (phase 2). */
export function canViewSuperAdmin(role?: UserRole | null): boolean {
  return role === "ADMIN";
}

export function hasRole(role: UserRole | null | undefined, allowed: UserRole[]): boolean {
  return !!role && allowed.includes(role);
}

export const ROLE_LABELS: Record<UserRole, string> = {
  ADMIN: "Platform Admin",
  OWNER: "Owner",
  MANAGER: "Manager",
  CASHIER: "Cashier",
  KITCHEN: "Kitchen",
  RIDER: "Rider",
  CUSTOMER: "Customer",
};
