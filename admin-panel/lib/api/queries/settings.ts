"use client";

import {
  useMutation,
  useQuery,
  useQueryClient,
} from "@tanstack/react-query";
import { toast } from "sonner";

import { api, ApiError } from "@/lib/api/client";
import { endpoints } from "@/lib/api/endpoints";
import { useAuthStore } from "@/store/auth-store";
import type {
  DeliveryZone,
  RestaurantDetail,
} from "@/types";

function errMsg(e: unknown, fallback: string) {
  return e instanceof ApiError ? e.message : fallback;
}

/** Current restaurant (profile + settings + fee config + hours) for prefill. */
export function useRestaurant() {
  const restaurantId = useAuthStore((s) => s.user?.restaurantId);
  return useQuery({
    queryKey: ["restaurant", restaurantId],
    queryFn: () =>
      api.get<RestaurantDetail>(endpoints.restaurant.detail(restaurantId!)),
    enabled: !!restaurantId,
  });
}

function useRestaurantInvalidate() {
  const qc = useQueryClient();
  return () => qc.invalidateQueries({ queryKey: ["restaurant"] });
}

export function useUpdateProfile() {
  const invalidate = useRestaurantInvalidate();
  return useMutation({
    mutationFn: (data: Record<string, unknown>) =>
      api.patch(endpoints.restaurant.profile, data),
    onSuccess: () => {
      toast.success("Profile saved");
      invalidate();
    },
    onError: (e) => toast.error(errMsg(e, "Couldn't save profile")),
  });
}

export function useUpdateSettings() {
  const invalidate = useRestaurantInvalidate();
  return useMutation({
    mutationFn: (data: Record<string, unknown>) =>
      api.patch(endpoints.restaurant.settings, data),
    onSuccess: () => {
      toast.success("Settings saved");
      invalidate();
    },
    onError: (e) => toast.error(errMsg(e, "Couldn't save settings")),
  });
}

export function useUpdateDeliveryFee() {
  const invalidate = useRestaurantInvalidate();
  return useMutation({
    mutationFn: (data: Record<string, unknown>) =>
      api.patch(endpoints.restaurant.deliveryFee, data),
    onSuccess: () => {
      toast.success("Delivery pricing saved");
      invalidate();
    },
    onError: (e) => toast.error(errMsg(e, "Couldn't save delivery pricing")),
  });
}

export function useUpsertHours() {
  const invalidate = useRestaurantInvalidate();
  return useMutation({
    mutationFn: ({
      day,
      openTime,
      closeTime,
      isClosed,
    }: {
      day: number;
      openTime: string;
      closeTime: string;
      isClosed?: boolean;
    }) =>
      api.post(endpoints.restaurant.operatingHours(day), {
        openTime,
        closeTime,
        isClosed,
      }),
    onSuccess: () => {
      toast.success("Hours updated");
      invalidate();
    },
    onError: (e) => toast.error(errMsg(e, "Couldn't update hours")),
  });
}

/* ── Delivery zones ─────────────────────────────────────────── */

export function useZones() {
  return useQuery({
    queryKey: ["zones"],
    queryFn: () => api.get<DeliveryZone[]>(endpoints.restaurant.zones),
  });
}

export function useSaveZone() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, ...data }: { id?: string } & Record<string, unknown>) =>
      id
        ? api.patch(endpoints.restaurant.zone(id), data)
        : api.post(endpoints.restaurant.zones, data),
    onSuccess: (_d, vars) => {
      toast.success(vars.id ? "Zone updated" : "Zone created");
      qc.invalidateQueries({ queryKey: ["zones"] });
    },
    onError: (e) => toast.error(errMsg(e, "Couldn't save zone")),
  });
}

export function useDeleteZone() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => api.delete(endpoints.restaurant.zone(id)),
    onSuccess: () => {
      toast.success("Zone deleted");
      qc.invalidateQueries({ queryKey: ["zones"] });
    },
    onError: (e) => toast.error(errMsg(e, "Couldn't delete zone")),
  });
}
