"use client";

import {
  useMutation,
  useQuery,
  useQueryClient,
} from "@tanstack/react-query";
import { toast } from "sonner";

import { api, ApiError } from "@/lib/api/client";
import { endpoints } from "@/lib/api/endpoints";
import type { PendingRider, RiderApprovalStatus, RiderListItem } from "@/types";

export function useRiders() {
  return useQuery({
    queryKey: ["riders", "list"],
    queryFn: () => api.get<RiderListItem[]>(endpoints.riders.list),
  });
}

export function usePendingRiders() {
  return useQuery({
    queryKey: ["riders", "pending"],
    queryFn: () => api.get<PendingRider[]>(endpoints.riders.pending),
  });
}

export function useUpdateRiderDocument() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({
      docId,
      status,
    }: {
      docId: string;
      status: "APPROVED" | "REJECTED" | "PENDING";
    }) => api.patch(endpoints.riders.document(docId), { status }),
    onSuccess: (_d, { status }) => {
      toast.success(
        status === "APPROVED"
          ? "Document approved"
          : status === "REJECTED"
            ? "Document rejected"
            : "Document reset"
      );
      qc.invalidateQueries({ queryKey: ["riders"] });
    },
    onError: (e) =>
      toast.error(e instanceof ApiError ? e.message : "Couldn't update document"),
  });
}

export function useApproveRider() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({
      id,
      status,
    }: {
      id: string;
      status: Extract<RiderApprovalStatus, "APPROVED" | "REJECTED" | "SUSPENDED">;
    }) => api.patch(endpoints.riders.approve(id), { status }),
    onSuccess: (_d, { status }) => {
      const msg =
        status === "APPROVED"
          ? "Rider approved"
          : status === "REJECTED"
            ? "Rider rejected"
            : "Rider suspended";
      toast.success(msg);
      qc.invalidateQueries({ queryKey: ["riders"] });
    },
    onError: (e) =>
      toast.error(e instanceof ApiError ? e.message : "Couldn't update rider"),
  });
}
