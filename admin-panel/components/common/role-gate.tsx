"use client";

import { useAuth } from "@/lib/auth/use-auth";
import { hasRole } from "@/lib/auth/roles";
import type { UserRole } from "@/types";

interface RoleGateProps {
  roles: UserRole[];
  children: React.ReactNode;
  fallback?: React.ReactNode;
}

/** Renders children only when the current user holds one of the allowed roles. */
export function RoleGate({ roles, children, fallback = null }: RoleGateProps) {
  const { role } = useAuth();
  return hasRole(role, roles) ? <>{children}</> : <>{fallback}</>;
}
