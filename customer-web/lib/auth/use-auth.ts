"use client";

import { useMutation, useQuery } from "@tanstack/react-query";
import { useRouter } from "next/navigation";

import { api } from "@/lib/api/client";
import { endpoints } from "@/lib/api/endpoints";
import { safeAuthRedirect } from "@/lib/auth/redirect";
import { normalizeAuthProfile } from "@/lib/auth/profile";
import { disconnectSocket } from "@/lib/realtime/socket";
import { useAuthStore } from "@/store/auth-store";
import type { LoginResponse } from "@/types";

export function useAuth() {
  const user = useAuthStore((s) => s.user);
  const hydrated = useAuthStore((s) => s.hydrated);
  return {
    user,
    role: user?.role ?? null,
    isAuthenticated: !!user,
    hydrated,
  };
}

/** The backend returns `user` as the JWT payload ({ sub, role, ... }). */
function normalizeSession(raw: Record<string, unknown>): LoginResponse {
  const p = (raw.user ?? {}) as Record<string, unknown>;
  const user = normalizeAuthProfile(p);
  return { user };
}

/** Step 1 of phone/email OTP sign-in. */
export function useSendOtp() {
  return useMutation({
    mutationFn: (input: { phone?: string; email?: string }) =>
      api.post(endpoints.auth.otpSend, { ...input, purpose: "LOGIN" }, { auth: false }),
  });
}

export function useSendPasswordResetOtp() {
  return useMutation({
    mutationFn: (input: { phone?: string; email?: string }) =>
      api.post(
        endpoints.auth.otpSend,
        { ...input, purpose: "RESET_PASSWORD" },
        { auth: false }
      ),
  });
}

export function useResetPassword() {
  return useMutation({
    mutationFn: (input: {
      phone?: string;
      email?: string;
      code: string;
      newPassword: string;
    }) =>
      api.post(endpoints.auth.passwordReset, input, { auth: false }),
  });
}

/** Step 2 of OTP sign-in — verifying returns a session. */
export function useVerifyOtp(next?: string | null) {
  const router = useRouter();
  const setUser = useAuthStore((s) => s.setUser);
  const setHydrated = useAuthStore((s) => s.setHydrated);
  return useMutation({
    mutationFn: async (input: { phone?: string; email?: string; code: string }) => {
      const raw = await api.post<Record<string, unknown>>(
        endpoints.auth.otpVerify,
        { ...input, purpose: "LOGIN" },
        { auth: false }
      );
      return normalizeSession(raw);
    },
    onSuccess: (session) => {
      setUser(session.user);
      setHydrated(true);
      router.replace(safeAuthRedirect(next));
    },
  });
}

export function usePasswordLogin(next?: string | null) {
  const router = useRouter();
  const setUser = useAuthStore((s) => s.setUser);
  const setHydrated = useAuthStore((s) => s.setHydrated);
  return useMutation({
    mutationFn: async (input: { emailOrPhone: string; password: string }) => {
      const isEmail = input.emailOrPhone.includes("@");
      const body = isEmail
        ? { email: input.emailOrPhone, password: input.password }
        : { phone: input.emailOrPhone, password: input.password };
      const raw = await api.post<Record<string, unknown>>(
        endpoints.auth.login,
        body,
        { auth: false }
      );
      return normalizeSession(raw);
    },
    onSuccess: (session) => {
      setUser(session.user);
      setHydrated(true);
      router.replace(safeAuthRedirect(next));
    },
  });
}

export function useRegister(next?: string | null) {
  const router = useRouter();
  const setUser = useAuthStore((s) => s.setUser);
  const setHydrated = useAuthStore((s) => s.setHydrated);
  return useMutation({
    mutationFn: async (input: {
      fullName: string;
      phone: string;
      email?: string;
      password: string;
    }) => {
      const raw = await api.post<Record<string, unknown>>(
        endpoints.auth.register,
        input,
        { auth: false }
      );
      return normalizeSession(raw);
    },
    onSuccess: (session) => {
      setUser(session.user);
      setHydrated(true);
      router.replace(safeAuthRedirect(next));
    },
  });
}

/** Profile details (name/phone/email) — the JWT payload omits them. */
export function useMe() {
  const { isAuthenticated } = useAuth();
  const setUser = useAuthStore((s) => s.setUser);
  return useQuery({
    queryKey: ["me"],
    enabled: isAuthenticated,
    queryFn: async () => {
      const raw = await api.get<Record<string, unknown>>(endpoints.users.me);
      const current = useAuthStore.getState().user;
      const me = normalizeAuthProfile(raw, current);
      setUser(me);
      return me;
    },
  });
}

export function useUpdateProfile() {
  const setUser = useAuthStore((state) => state.setUser);
  return useMutation({
    mutationFn: (input: { fullName: string }) =>
      api.patch<Record<string, unknown>>(endpoints.users.me, input),
    onSuccess: (profile) => {
      setUser(normalizeAuthProfile(profile, useAuthStore.getState().user));
    },
  });
}

export function useLogout() {
  const router = useRouter();
  const logout = useAuthStore((s) => s.logout);
  return () => {
    void api.post(endpoints.auth.logout).catch(() => undefined);
    disconnectSocket();
    logout();
    router.replace("/login");
  };
}
