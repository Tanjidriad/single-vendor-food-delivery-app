import { create } from "zustand";
import { persist } from "zustand/middleware";

import type { AuthUser } from "@/types";

interface AuthState {
  user: AuthUser | null;
  hydrated: boolean;
  setUser: (user: AuthUser) => void;
  setHydrated: (value: boolean) => void;
  logout: () => void;
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      user: null,
      hydrated: false,
      setUser: (user) => set({ user }),
      setHydrated: (hydrated) => set({ hydrated }),
      logout: () => set({ user: null }),
    }),
    {
      name: "customer-auth",
      version: 2,
      migrate: (persisted) => {
        const previous = persisted as Partial<AuthState> | undefined;
        return { user: previous?.user ?? null };
      },
      partialize: (state) => ({ user: state.user }),
    }
  )
);
