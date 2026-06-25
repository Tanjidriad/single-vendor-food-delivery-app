"use client";

import { useQuery } from "@tanstack/react-query";

import { api } from "@/lib/api/client";
import { endpoints } from "@/lib/api/endpoints";
import type { Order } from "@/types";

export interface OpsQueues {
  stuckDeliveries: Order[];
  failedDeliveries: Order[];
  returnedOrders: Order[];
}

export function useOpsQueues() {
  return useQuery({
    queryKey: ["ops", "queues"],
    queryFn: () => api.get<OpsQueues>(endpoints.orders.opsQueues),
    refetchInterval: 20_000,
  });
}
