"use client";

import { useQuery } from "@tanstack/react-query";

import { api } from "@/lib/api/client";
import { endpoints } from "@/lib/api/endpoints";
import type { Banner, MenuCategory, MenuItem, Restaurant, Review } from "@/types";

const RESTAURANT_SLUG = process.env.NEXT_PUBLIC_RESTAURANT_SLUG || "wasabi";
const RESTAURANT_ID = process.env.NEXT_PUBLIC_RESTAURANT_ID || "";

interface RawAddonJoin {
  addon: { id: string; name: string; price: number };
}
interface RawItem {
  id: string;
  name: string;
  description?: string | null;
  price: number;
  imageUrl?: string | null;
  isAvailable?: boolean;
  isFeatured?: boolean;
  addons?: RawAddonJoin[];
}
interface RawCategory {
  id: string;
  name: string;
  items?: RawItem[];
  menuItems?: RawItem[];
}

function mapItem(raw: RawItem): MenuItem {
  return {
    id: raw.id,
    name: raw.name,
    description: raw.description,
    price: raw.price,
    imageUrl: raw.imageUrl,
    isAvailable: raw.isAvailable ?? true,
    isFeatured: raw.isFeatured ?? false,
    addons: (raw.addons ?? []).map((a) => a.addon).filter(Boolean),
  };
}

/** Resolve the storefront's single restaurant id (by slug unless an id is pinned). */
export function useRestaurantId() {
  return useQuery({
    queryKey: ["restaurant-id", RESTAURANT_ID || RESTAURANT_SLUG],
    queryFn: async () => {
      if (RESTAURANT_ID) return RESTAURANT_ID;
      const r = await api.get<{ id: string }>(
        endpoints.restaurant.bySlug(RESTAURANT_SLUG),
        { auth: false }
      );
      return r.id;
    },
    staleTime: Infinity,
  });
}

/** Full storefront restaurant record (identity, contact, hours, coords). */
export function useRestaurant() {
  return useQuery({
    queryKey: ["restaurant", RESTAURANT_ID || RESTAURANT_SLUG],
    queryFn: () =>
      api.get<Restaurant>(
        RESTAURANT_ID
          ? endpoints.restaurant.byId(RESTAURANT_ID)
          : endpoints.restaurant.bySlug(RESTAURANT_SLUG),
        { auth: false }
      ),
    staleTime: 5 * 60 * 1000,
  });
}

/** Active, in-window promotional banners for the storefront slider. */
export function usePromoBanners() {
  const { data: restaurantId } = useRestaurantId();
  return useQuery({
    queryKey: ["banners", restaurantId],
    enabled: !!restaurantId,
    queryFn: () =>
      api.get<Banner[]>(endpoints.menu.banners(restaurantId!), {
        auth: false,
      }),
    staleTime: 5 * 60 * 1000,
  });
}

/** Available featured dishes configured by the restaurant. */
export function useFeaturedMenu() {
  const { data: restaurantId } = useRestaurantId();
  return useQuery({
    queryKey: ["featured-menu", restaurantId],
    enabled: !!restaurantId,
    queryFn: async () => {
      const raw = await api.get<RawItem[]>(
        endpoints.menu.featured(restaurantId!),
        { auth: false }
      );
      return raw.map(mapItem);
    },
    staleTime: 5 * 60 * 1000,
  });
}

interface RawReview {
  id: string;
  rating: number;
  comment?: string | null;
  createdAt: string;
  user?: {
    customerProfile?: { fullName?: string; avatarUrl?: string | null } | null;
  } | null;
}

/** Verified customer reviews (only left on delivered orders, server-side). */
export function useReviews() {
  const { data: restaurantId } = useRestaurantId();
  return useQuery({
    queryKey: ["reviews", restaurantId],
    enabled: !!restaurantId,
    queryFn: async () => {
      const raw = await api.get<RawReview[]>(
        endpoints.reviews.byRestaurant(restaurantId!),
        { auth: false }
      );
      return raw.map<Review>((r) => ({
        id: r.id,
        rating: r.rating,
        comment: r.comment ?? null,
        createdAt: r.createdAt,
        authorName: r.user?.customerProfile?.fullName ?? "Wasabi guest",
        avatarUrl: r.user?.customerProfile?.avatarUrl ?? null,
      }));
    },
    staleTime: 5 * 60 * 1000,
  });
}

export function useMenu() {
  const restaurant = useRestaurantId();
  const restaurantId = restaurant.data;
  const menu = useQuery({
    queryKey: ["menu", restaurantId],
    enabled: !!restaurantId,
    queryFn: async () => {
      const raw = await api.get<RawCategory[]>(
        endpoints.menu.byRestaurant(restaurantId!),
        { auth: false }
      );
      return raw
        .map<MenuCategory>((c) => ({
          id: c.id,
          name: c.name,
          items: (c.items ?? c.menuItems ?? []).map(mapItem),
        }))
        .filter((c) => c.items.length > 0);
    },
  });
  return { restaurantId, ...menu };
}
