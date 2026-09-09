"use client";

import { useQuery } from "@tanstack/react-query";

import { api, qs } from "@/lib/api/client";
import { endpoints } from "@/lib/api/endpoints";
import { useRestaurantId } from "@/lib/api/queries/menu";
import type { PublicCoupon } from "@/types";

export function usePublicCoupons() {
  const { data: restaurantId } = useRestaurantId();
  return useQuery({
    queryKey: ["public-coupons", restaurantId],
    enabled: !!restaurantId,
    queryFn: () =>
      api.get<PublicCoupon[]>(
        endpoints.coupons.public + qs({ restaurantId }),
        { auth: false }
      ),
    staleTime: 5 * 60 * 1000,
  });
}
