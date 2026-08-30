"use client";

import { useMutation } from "@tanstack/react-query";

import { api, qs } from "@/lib/api/client";
import { endpoints } from "@/lib/api/endpoints";
import type { CouponValidation, DeliveryQuote } from "@/types";

export interface GeoResult {
  address: string;
  latitude: number;
  longitude: number;
}

/** Resolve a typed address string to coordinates (public endpoint). */
export function geocodeAddress(address: string) {
  return api.get<GeoResult>(endpoints.deliveryFee.geocode + qs({ address }), {
    auth: false,
  });
}

/** Resolve coordinates (e.g. from the browser) to a human address. */
export function reverseGeocode(lat: number, lng: number) {
  return api.get<GeoResult>(
    endpoints.deliveryFee.reverseGeocode + qs({ lat, lng }),
    { auth: false }
  );
}

/** Route-based delivery fee for a drop-off point (auth required). */
export function useDeliveryQuote() {
  return useMutation({
    mutationFn: (input: {
      restaurantId: string;
      deliveryLat: number;
      deliveryLng: number;
      subtotal?: number;
    }) => api.post<DeliveryQuote>(endpoints.deliveryFee.quote, input),
  });
}

/** Validate a coupon against the current subtotal. Throws on invalid. */
export function useValidateCoupon() {
  return useMutation({
    mutationFn: (input: {
      restaurantId: string;
      code: string;
      subtotal: number;
    }) =>
      api.post<CouponValidation>(endpoints.coupons.validate, input, {
        auth: false,
      }),
  });
}
