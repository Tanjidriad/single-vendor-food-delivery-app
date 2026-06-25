"use client";

import {
  useMutation,
  useQuery,
  useQueryClient,
} from "@tanstack/react-query";
import { toast } from "sonner";

import { api, ApiError } from "@/lib/api/client";
import { endpoints } from "@/lib/api/endpoints";
import type { Banner, Coupon } from "@/types";

function errMsg(e: unknown, fallback: string) {
  return e instanceof ApiError ? e.message : fallback;
}

/* ── Banners ────────────────────────────────────────────────── */

export function useBanners() {
  return useQuery({
    queryKey: ["banners"],
    queryFn: () => api.get<Banner[]>(endpoints.restaurant.banners),
  });
}

export function useSaveBanner() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, ...data }: { id?: string } & Record<string, unknown>) =>
      id
        ? api.patch(endpoints.restaurant.banner(id), data)
        : api.post(endpoints.restaurant.banners, data),
    onSuccess: (_d, vars) => {
      toast.success(vars.id ? "Banner updated" : "Banner created");
      qc.invalidateQueries({ queryKey: ["banners"] });
    },
    onError: (e) => toast.error(errMsg(e, "Couldn't save banner")),
  });
}

export function useDeleteBanner() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => api.delete(endpoints.restaurant.banner(id)),
    onSuccess: () => {
      toast.success("Banner deleted");
      qc.invalidateQueries({ queryKey: ["banners"] });
    },
    onError: (e) => toast.error(errMsg(e, "Couldn't delete banner")),
  });
}

/* ── Coupons ────────────────────────────────────────────────── */

export function useCoupons() {
  return useQuery({
    queryKey: ["coupons"],
    queryFn: () => api.get<Coupon[]>(endpoints.restaurant.coupons),
  });
}

export function useSaveCoupon() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, ...data }: { id?: string } & Record<string, unknown>) =>
      id
        ? api.patch(endpoints.restaurant.coupon(id), data)
        : api.post(endpoints.restaurant.coupons, data),
    onSuccess: (_d, vars) => {
      toast.success(vars.id ? "Coupon updated" : "Coupon created");
      qc.invalidateQueries({ queryKey: ["coupons"] });
    },
    onError: (e) => toast.error(errMsg(e, "Couldn't save coupon")),
  });
}

export function useDeleteCoupon() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => api.delete(endpoints.restaurant.coupon(id)),
    onSuccess: () => {
      toast.success("Coupon deleted");
      qc.invalidateQueries({ queryKey: ["coupons"] });
    },
    onError: (e) => toast.error(errMsg(e, "Couldn't delete coupon")),
  });
}
