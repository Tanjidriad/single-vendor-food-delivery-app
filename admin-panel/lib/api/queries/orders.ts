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
  ListResponse,
  Order,
  OrderListItem,
  OrderStatus,
} from "@/types";

export interface OrderFilters {
  status?: OrderStatus | "";
  search?: string;
  from?: string;
  to?: string;
  page?: number;
  limit?: number;
}

export function useOrders(filters: OrderFilters) {
  return useQuery({
    queryKey: ["orders", "list", filters],
    queryFn: () =>
      api.get<ListResponse<OrderListItem>>(
        `${endpoints.orders.list}${qs({
          status: filters.status,
          search: filters.search,
          from: filters.from,
          to: filters.to,
          page: filters.page ?? 1,
          limit: filters.limit ?? 25,
        })}`
      ),
    placeholderData: (prev) => prev,
  });
}

export function useOrderDetail(id: string | null) {
  return useQuery({
    queryKey: ["orders", "detail", id],
    queryFn: () => api.get<Order>(endpoints.orders.detail(id!)),
    enabled: !!id,
  });
}

function errMsg(e: unknown, fallback: string) {
  return e instanceof ApiError ? e.message : fallback;
}

/** Shared invalidation after any order mutation. */
function useOrderInvalidation() {
  const qc = useQueryClient();
  return (id?: string) => {
    qc.invalidateQueries({ queryKey: ["orders"] });
    qc.invalidateQueries({ queryKey: ["dashboard"] });
    qc.invalidateQueries({ queryKey: ["ops"] });
    if (id) qc.invalidateQueries({ queryKey: ["orders", "detail", id] });
  };
}

export function useAcceptOrder() {
  const invalidate = useOrderInvalidation();
  return useMutation({
    mutationFn: ({ id, prepMinutes }: { id: string; prepMinutes?: number }) =>
      api.post(endpoints.orders.accept(id), { prepMinutes }),
    onSuccess: (_d, { id }) => {
      toast.success("Order accepted");
      invalidate(id);
    },
    onError: (e) => toast.error(errMsg(e, "Couldn't accept order")),
  });
}

export function useRejectOrder() {
  const invalidate = useOrderInvalidation();
  return useMutation({
    mutationFn: ({ id, note }: { id: string; note?: string }) =>
      api.post(endpoints.orders.reject(id), { note }),
    onSuccess: (_d, { id }) => {
      toast.success("Order rejected");
      invalidate(id);
    },
    onError: (e) => toast.error(errMsg(e, "Couldn't reject order")),
  });
}

export function useCancelOrder() {
  const invalidate = useOrderInvalidation();
  return useMutation({
    mutationFn: ({ id, reason }: { id: string; reason?: string }) =>
      api.post(endpoints.orders.cancel(id), { reason }),
    onSuccess: (_d, { id }) => {
      toast.success("Order cancelled");
      invalidate(id);
    },
    onError: (e) => toast.error(errMsg(e, "Couldn't cancel order")),
  });
}

export function useUpdateOrderStatus() {
  const invalidate = useOrderInvalidation();
  return useMutation({
    mutationFn: ({
      id,
      status,
      prepMinutes,
    }: {
      id: string;
      status: OrderStatus;
      prepMinutes?: number;
    }) => api.patch(endpoints.orders.updateStatus(id), { status, prepMinutes }),
    onSuccess: (_d, { id }) => {
      toast.success("Order updated");
      invalidate(id);
    },
    onError: (e) => toast.error(errMsg(e, "Couldn't update order")),
  });
}
