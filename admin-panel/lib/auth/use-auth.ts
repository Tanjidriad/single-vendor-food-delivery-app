"use client";

import { useMutation } from "@tanstack/react-query";
import { useRouter } from "next/navigation";

import { api } from "@/lib/api/client";
import { endpoints } from "@/lib/api/endpoints";
import { isStaff } from "@/lib/auth/roles";
import { useAuthStore } from "@/store/auth-store";
import type { AuthUser, LoginResponse } from "@/types";

export function useAuth() {
  const user = useAuthStore((s) => s.user);
  const accessToken = useAuthStore((s) => s.accessToken);
  const hydrated = useAuthStore((s) => s.hydrated);
  return {
    user,
    role: user?.role ?? null,
    isAuthenticated: !!accessToken && !!user,
    hydrated,
  };
}

interface LoginPayload {
  emailOrPhone: string;
  password: string;
}

function normalizeLoginResponse(raw: Record<string, unknown>): LoginResponse {
  const accessToken = (raw.accessToken ?? raw.access_token) as string;
  const refreshToken = (raw.refreshToken ?? raw.refresh_token) as string;
  // The backend returns the JWT payload as `user` ({ sub, role, restaurantId, … }).
  const p = (raw.user ?? raw.profile ?? {}) as Record<string, unknown>;
  const user: AuthUser = {
    id: (p.id ?? p.sub) as string,
    email: (p.email as string) ?? null,
    phone: (p.phone as string) ?? null,
    role: p.role as AuthUser["role"],
    restaurantId: (p.restaurantId as string) ?? null,
    branchId: (p.branchId as string) ?? null,
    fullName: (p.fullName as string) ?? null,
  };
  return { accessToken, refreshToken, user };
}

export function useLogin() {
  const router = useRouter();
  const setSession = useAuthStore((s) => s.setSession);

  return useMutation({
    mutationFn: async ({ emailOrPhone, password }: LoginPayload) => {
      const isEmail = emailOrPhone.includes("@");
      const body = isEmail
        ? { email: emailOrPhone, password }
        : { phone: emailOrPhone, password };
      const raw = await api.post<Record<string, unknown>>(
        endpoints.auth.login,
        body,
        { auth: false }
      );
      const session = normalizeLoginResponse(raw);
      if (!isStaff(session.user?.role)) {
        throw new Error(
          "This account doesn't have access to the admin panel."
        );
      }
      // The token payload omits email/phone — backfill from what they typed.
      if (isEmail && !session.user.email) session.user.email = emailOrPhone;
      if (!isEmail && !session.user.phone) session.user.phone = emailOrPhone;
      return session;
    },
    onSuccess: (session) => {
      setSession(session);
      router.replace("/");
    },
  });
}

export function useLogout() {
  const router = useRouter();
  const logout = useAuthStore((s) => s.logout);
  return () => {
    // Fire-and-forget server revoke; clear locally regardless.
    api.post(endpoints.auth.logout).catch(() => {});
    logout();
    router.replace("/login");
  };
}
