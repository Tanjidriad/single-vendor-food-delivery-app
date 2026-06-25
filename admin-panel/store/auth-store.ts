import { create } from "zustand";
import { persist } from "zustand/middleware";

import type { AuthUser } from "@/types";

interface AuthState {
  accessToken: string | null;
  refreshToken: string | null;
  user: AuthUser | null;
  hydrated: boolean;
  setSession: (data: {
    accessToken: string;
    refreshToken: string;
    user: AuthUser;
  }) => void;
  setAccessToken: (token: string) => void;
  setHydrated: (v: boolean) => void;
  logout: () => void;
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      accessToken: null,
      refreshToken: null,
      user: null,
      hydrated: false,
      setSession: ({ accessToken, refreshToken, user }) =>
        set({ accessToken, refreshToken, user }),
      setAccessToken: (token) => set({ accessToken: token }),
      setHydrated: (v) => set({ hydrated: v }),
      logout: () => set({ accessToken: null, refreshToken: null, user: null }),
    }),
    {
      name: "admin-auth",
      partialize: (s) => ({
        accessToken: s.accessToken,
        refreshToken: s.refreshToken,
        user: s.user,
      }),
      onRehydrateStorage: () => (state) => {
        state?.setHydrated(true);
      },
    }
  )
);
