"use client";

import { useQuery } from "@tanstack/react-query";

import { api, qs } from "@/lib/api/client";
import { endpoints } from "@/lib/api/endpoints";
import type {
  DashboardStats,
  DailyRevenuePoint,
  ListResponse,
  OrderListItem,
  PopularItem,
} from "@/types";

export function useDashboardStats() {
  return useQuery({
    queryKey: ["dashboard", "stats"],
    queryFn: () => api.get<DashboardStats>(endpoints.dashboard.stats),
  });
}

export function useDailyRevenue(days = 7) {
  return useQuery({
    queryKey: ["dashboard", "revenue", days],
    queryFn: () =>
      api.get<DailyRevenuePoint[]>(
        `${endpoints.dashboard.dailyRevenue}${qs({ days })}`
      ),
  });
}

export function useRecentOrders(limit = 6) {
  return useQuery({
    queryKey: ["dashboard", "recent-orders", limit],
    queryFn: () =>
      api.get<ListResponse<OrderListItem>>(
        `${endpoints.orders.list}${qs({ page: 1, limit })}`
      ),
    select: (res) => res.data,
  });
}

export function usePopularItems(limit = 5) {
  return useQuery({
    queryKey: ["dashboard", "popular-items", limit],
    queryFn: () =>
      api.get<PopularItem[]>(`${endpoints.reports.popularItems}${qs({ limit })}`),
  });
}
