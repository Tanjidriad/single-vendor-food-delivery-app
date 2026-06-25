// Typed endpoint map mirroring the NestJS backend routes (api/v1 prefix is in API_BASE_URL).
// Split by surface so the future super-admin (/admin/super/*) slots in cleanly later.

export const endpoints = {
  auth: {
    login: "/auth/login",
    refresh: "/auth/refresh",
    logout: "/auth/logout",
    me: "/users/me",
  },

  // Single-restaurant back office (OWNER / MANAGER / ADMIN)
  dashboard: {
    stats: "/admin/dashboard/stats",
    dailyRevenue: "/admin/reports/daily-revenue",
  },

  orders: {
    list: "/admin/orders",
    detail: (id: string) => `/orders/${id}`,
    opsQueues: "/orders/ops/queues",
    accept: (id: string) => `/orders/${id}/accept`,
    reject: (id: string) => `/orders/${id}/reject`,
    cancel: (id: string) => `/orders/${id}/cancel`,
    updateStatus: (id: string) => `/orders/${id}/status`,
    resolveException: (id: string) => `/orders/${id}/resolve-exception`,
    foodDisposition: (id: string) => `/orders/${id}/food-disposition`,
  },

  dispatch: {
    availableRiders: "/dispatch/riders/available",
    autoAssign: (orderId: string) => `/dispatch/orders/${orderId}/auto-assign`,
    assign: (orderId: string) => `/dispatch/orders/${orderId}/assign`,
    forceUnassign: (orderId: string) => `/dispatch/orders/${orderId}/force-unassign`,
  },

  menu: {
    all: "/admin/menu",
    categories: "/admin/menu/categories",
    category: (id: string) => `/admin/menu/categories/${id}`,
    items: "/admin/menu/items",
    item: (id: string) => `/admin/menu/items/${id}`,
    addons: "/admin/menu/addons",
    addon: (id: string) => `/admin/menu/addons/${id}`,
    linkAddon: (itemId: string, addonId: string) =>
      `/admin/menu/items/${itemId}/addons/${addonId}`,
  },

  users: {
    list: "/admin/users",
    detail: (id: string) => `/admin/users/${id}`,
    status: (id: string) => `/admin/users/${id}/status`,
  },

  riders: {
    list: "/admin/riders",
    pending: "/admin/riders/pending",
    approve: (id: string) => `/admin/riders/${id}/approve`,
    document: (docId: string) => `/admin/riders/documents/${docId}`,
  },

  restaurant: {
    detail: (id: string) => `/restaurant/${id}`,
    profile: "/admin/restaurant/profile",
    settings: "/admin/restaurant/settings",
    deliveryFee: "/admin/restaurant/delivery-fee",
    operatingHours: (day: number) => `/admin/restaurant/operating-hours/${day}`,
    banners: "/admin/restaurant/banners",
    banner: (id: string) => `/admin/restaurant/banners/${id}`,
    coupons: "/admin/restaurant/coupons",
    coupon: (id: string) => `/admin/restaurant/coupons/${id}`,
    zones: "/admin/restaurant/zones",
    zone: (id: string) => `/admin/restaurant/zones/${id}`,
  },

  reports: {
    sales: "/reports/sales",
    popularItems: "/reports/popular-items",
    earnings: "/reports/earnings",
    riders: "/reports/riders",
  },

  complaints: {
    list: "/admin/complaints",
    update: (id: string) => `/admin/complaints/${id}`,
  },

  earnings: {
    riderLedger: (riderId: string) => `/earnings/riders/${riderId}/ledger`,
    riderPayouts: (riderId: string) => `/earnings/riders/${riderId}/payouts`,
    pendingCod: "/earnings/cod-settlements/pending",
    settleCod: (orderId: string) => `/earnings/cod-settlements/${orderId}/settle`,
  },

  uploads: {
    image: "/uploads/image",
  },

  // Future phase 2 — platform-wide super admin (ADMIN only). Not used yet.
  super: {
    stats: "/admin/super/stats",
    revenue: "/admin/super/revenue",
    orders: "/admin/super/orders",
    restaurants: "/admin/super/restaurants",
  },
} as const;
