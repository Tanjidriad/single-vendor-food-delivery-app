"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import { api } from "@/lib/api/client";
import { endpoints } from "@/lib/api/endpoints";
import { useAuth } from "@/lib/auth/use-auth";
import type { Complaint, ComplaintType } from "@/types";

export interface ComplaintInput {
  orderId: string;
  type: ComplaintType;
  subject: string;
  description: string;
  refundAmount?: number;
}

/** The customer's submitted complaints / refund requests. */
export function useComplaints() {
  const { isAuthenticated } = useAuth();
  return useQuery({
    queryKey: ["complaints"],
    enabled: isAuthenticated,
    queryFn: () => api.get<Complaint[]>(endpoints.complaints.mine),
  });
}

export function useCreateComplaint() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (input: ComplaintInput) =>
      api.post<Complaint>(endpoints.complaints.create, input),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["complaints"] }),
  });
}
