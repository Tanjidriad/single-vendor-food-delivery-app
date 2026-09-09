"use client";

import {
  useMutation,
  useQuery,
  useQueryClient,
} from "@tanstack/react-query";

import { api } from "@/lib/api/client";
import { endpoints } from "@/lib/api/endpoints";
import { useAuth } from "@/lib/auth/use-auth";
import type {
  Order,
  OrderType,
  PaymentMethod,
} from "@/types";

export interface PlaceOrderItemInput {
  menuItemId: string;
  quantity: number;
  notes?: string;
  addons?: { addonId: string }[];
}

export interface PlaceOrderInput {
  restaurantId: string;
  orderType: OrderType;
  paymentMethod: PaymentMethod;
  items: PlaceOrderItemInput[];
  couponCode?: string;
  deliveryAddress?: string;
  deliveryLat?: number;
  deliveryLng?: number;
  deliveryNote?: string;
  customerName?: string;
  customerPhone?: string;
  idempotencyKey?: string;
}

export function usePlaceOrder() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (input: PlaceOrderInput) =>
      api.post<Order>(endpoints.orders.place, input),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["orders"] }),
  });
}

/** Customer's order history (most recent first). */
export function useOrders() {
  const { isAuthenticated } = useAuth();
  return useQuery({
    queryKey: ["orders"],
    enabled: isAuthenticated,
    queryFn: () => api.get<Order[]>(endpoints.orders.list),
  });
}

/** A single order. Polls as a fallback; realtime updates refresh it live. */
export function useOrder(id: string | undefined, opts?: { poll?: boolean }) {
  const { isAuthenticated } = useAuth();
  return useQuery({
    queryKey: ["order", id],
    enabled: isAuthenticated && !!id,
    queryFn: () => api.get<Order>(endpoints.orders.byId(id!)),
    refetchInterval: opts?.poll ? 20000 : false,
  });
}

export function useCancelOrder() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, reason }: { id: string; reason?: string }) =>
      api.post<Order>(endpoints.orders.cancel(id), { reason }),
    onSuccess: (_data, { id }) => {
      qc.invalidateQueries({ queryKey: ["order", id] });
      qc.invalidateQueries({ queryKey: ["orders"] });
    },
  });
}

export function useConfirmDelivery() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: string) =>
      api.post<Order>(endpoints.orders.confirmDelivery(id)),
    onSuccess: (_data, id) => {
      qc.invalidateQueries({ queryKey: ["order", id] });
      qc.invalidateQueries({ queryKey: ["orders"] });
    },
  });
}

export function useReorder() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => api.post<Order>(endpoints.orders.reorder(id)),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["orders"] }),
  });
}
