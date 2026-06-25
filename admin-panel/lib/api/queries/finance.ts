"use client";

import {
  useMutation,
  useQuery,
  useQueryClient,
} from "@tanstack/react-query";
import { toast } from "sonner";

import { api, ApiError, qs } from "@/lib/api/client";
import { endpoints } from "@/lib/api/endpoints";
import type {
  CodSettlement,
  Complaint,
  ComplaintStatus,
  EarningsReport,
  ReportPeriod,
  RiderPerformance,
  SalesSummary,
} from "@/types";

function errMsg(e: unknown, fallback: string) {
  return e instanceof ApiError ? e.message : fallback;
}

/* ── Reports ────────────────────────────────────────────────── */

export function useSalesReport(period: ReportPeriod) {
  return useQuery({
    queryKey: ["reports", "sales", period],
    queryFn: () =>
      api.get<SalesSummary>(`${endpoints.reports.sales}${qs({ period })}`),
  });
}

export function useEarningsReport(period: ReportPeriod) {
  return useQuery({
    queryKey: ["reports", "earnings", period],
    queryFn: () =>
      api.get<EarningsReport>(`${endpoints.reports.earnings}${qs({ period })}`),
  });
}

export function useRiderPerformance() {
  return useQuery({
    queryKey: ["reports", "riders"],
    queryFn: () => api.get<RiderPerformance[]>(endpoints.reports.riders),
  });
}

/* ── Complaints ─────────────────────────────────────────────── */

export function useComplaints(status?: ComplaintStatus | "") {
  return useQuery({
    queryKey: ["complaints", status || "all"],
    queryFn: () =>
      api.get<Complaint[]>(`${endpoints.complaints.list}${qs({ status })}`),
  });
}

export function useUpdateComplaint() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({
      id,
      ...data
    }: {
      id: string;
      status?: ComplaintStatus;
      staffNote?: string;
      refundAmount?: number;
    }) => api.patch(endpoints.complaints.update(id), data),
    onSuccess: () => {
      toast.success("Complaint updated");
      qc.invalidateQueries({ queryKey: ["complaints"] });
    },
    onError: (e) => toast.error(errMsg(e, "Couldn't update complaint")),
  });
}

/* ── COD settlements ────────────────────────────────────────── */

export function usePendingCod() {
  return useQuery({
    queryKey: ["settlements", "cod-pending"],
    queryFn: () => api.get<CodSettlement[]>(endpoints.earnings.pendingCod),
  });
}

export function useSettleCod() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({
      orderId,
      foodAmountRemitted,
      note,
    }: {
      orderId: string;
      foodAmountRemitted?: number;
      note?: string;
    }) => api.post(endpoints.earnings.settleCod(orderId), { foodAmountRemitted, note }),
    onSuccess: () => {
      toast.success("Settlement recorded");
      qc.invalidateQueries({ queryKey: ["settlements"] });
    },
    onError: (e) => toast.error(errMsg(e, "Couldn't record settlement")),
  });
}
