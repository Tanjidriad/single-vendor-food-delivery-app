// Customer-facing endpoints on the NestJS backend (prefix /api/v1 is in API_BASE_URL).
export const endpoints = {
  auth: {
    register: "/auth/register",
    login: "/auth/login",
    otpSend: "/auth/otp/send",
    otpVerify: "/auth/otp/verify",
    passwordReset: "/auth/forgot-password/reset",
    refresh: "/auth/refresh",
    logout: "/auth/logout",
  },
  users: {
    me: "/users/me",
  },
  menu: {
    byRestaurant: (id: string) => `/menu/restaurant/${id}`,
    featured: (id: string) => `/menu/restaurant/${id}/featured`,
    banners: (id: string) => `/menu/restaurant/${id}/banners`,
    filter: (id: string) => `/menu/restaurant/${id}/filter`,
    search: (id: string) => `/menu/restaurant/${id}/search`,
    item: (itemId: string) => `/menu/items/${itemId}`,
  },
  restaurant: {
    bySlug: (slug: string) => `/restaurant/slug/${slug}`,
    byId: (id: string) => `/restaurant/${id}`,
  },
  addresses: {
    list: "/addresses",
    create: "/addresses",
    update: (id: string) => `/addresses/${id}`,
    remove: (id: string) => `/addresses/${id}`,
  },
  deliveryFee: {
    quote: "/delivery-fee/quote",
    geocode: "/delivery-fee/geocode",
    reverseGeocode: "/delivery-fee/reverse-geocode",
  },
  orders: {
    place: "/orders",
    list: "/orders",
    byId: (id: string) => `/orders/${id}`,
    cancel: (id: string) => `/orders/${id}/cancel`,
    reorder: (id: string) => `/orders/${id}/reorder`,
    confirmDelivery: (id: string) => `/orders/${id}/confirm-delivery`,
  },
  payments: {
    initiate: (orderId: string) =>
      `/payments/orders/${orderId}/online/initiate`,
    execute: (orderId: string) =>
      `/payments/orders/${orderId}/online/execute`,
  },
  coupons: {
    public: "/coupons/public",
    validate: "/coupons/validate",
  },
  reviews: {
    byRestaurant: (id: string) => `/reviews/restaurant/${id}`,
    create: (orderId: string) => `/reviews/orders/${orderId}`,
  },
  favorites: {
    list: "/favorites",
    add: (menuItemId: string) => `/favorites/${menuItemId}`,
    remove: (menuItemId: string) => `/favorites/${menuItemId}`,
  },
  complaints: {
    create: "/complaints",
    mine: "/complaints/me",
  },
  notifications: {
    list: "/notifications",
    markRead: (id: string) => `/notifications/${id}/read`,
  },
} as const;
