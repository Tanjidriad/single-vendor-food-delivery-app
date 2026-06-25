"use client";

import {
  useMutation,
  useQuery,
  useQueryClient,
} from "@tanstack/react-query";
import { toast } from "sonner";

import { api, ApiError } from "@/lib/api/client";
import { endpoints } from "@/lib/api/endpoints";
import type { AvailableRider } from "@/types";

export function useAvailableRiders(enabled = true) {
  return useQuery({
    queryKey: ["dispatch", "available-riders"],
    queryFn: () =>
      api.get<AvailableRider[]>(endpoints.dispatch.availableRiders),
    enabled,
    staleTime: 10_000,
  });
}

function errMsg(e: unknown, fallback: string) {
  return e instanceof ApiError ? e.message : fallback;
}

function useDispatchInvalidation() {
  const qc = useQueryClient();
  return () => {
    qc.invalidateQueries({ queryKey: ["orders"] });
    qc.invalidateQueries({ queryKey: ["ops"] });
    qc.invalidateQueries({ queryKey: ["dispatch"] });
    qc.invalidateQueries({ queryKey: ["dashboard"] });
  };
}

export function useAutoAssign() {
  const invalidate = useDispatchInvalidation();
  return useMutation({
    mutationFn: (orderId: string) =>
      api.post(endpoints.dispatch.autoAssign(orderId)),
    onSuccess: () => {
      toast.success("Auto-assigning the best available rider");
      invalidate();
    },
    onError: (e) => toast.error(errMsg(e, "Couldn't auto-assign a rider")),
  });
}

export function useAssignRider() {
  const invalidate = useDispatchInvalidation();
  return useMutation({
    mutationFn: ({ orderId, riderId }: { orderId: string; riderId: string }) =>
      api.post(endpoints.dispatch.assign(orderId), { riderProfileId: riderId }),
    onSuccess: () => {
      toast.success("Rider assigned");
      invalidate();
    },
    onError: (e) => toast.error(errMsg(e, "Couldn't assign rider")),
  });
}

export function useForceUnassign() {
  const invalidate = useDispatchInvalidation();
  return useMutation({
    mutationFn: ({ orderId, reason }: { orderId: string; reason?: string }) =>
      api.post(endpoints.dispatch.forceUnassign(orderId), { reason }),
    onSuccess: () => {
      toast.success("Rider unassigned");
      invalidate();
    },
    onError: (e) => toast.error(errMsg(e, "Couldn't unassign rider")),
  });
}
