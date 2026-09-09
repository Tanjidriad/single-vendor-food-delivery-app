"use client";

import { useEffect } from "react";

import { api } from "@/lib/api/client";
import { endpoints } from "@/lib/api/endpoints";
import { useAuthStore } from "@/store/auth-store";
import { normalizeAuthProfile } from "@/lib/auth/profile";

export function AuthBootstrap() {
  const setUser = useAuthStore((state) => state.setUser);
  const setHydrated = useAuthStore((state) => state.setHydrated);
  const logout = useAuthStore((state) => state.logout);

  useEffect(() => {
    let active = true;

    api
      .get<Record<string, unknown>>(endpoints.users.me)
      .then((profile) => {
        if (active) setUser(normalizeAuthProfile(profile));
      })
      .catch(() => {
        if (active) logout();
      })
      .finally(() => {
        if (active) setHydrated(true);
      });

    return () => {
      active = false;
    };
  }, [logout, setHydrated, setUser]);

  return null;
}
