// Shared API types — mirror the backend Prisma schema (backend/prisma/schema.prisma).

export type UserRole =
  | "ADMIN"
  | "OWNER"
  | "MANAGER"
  | "CASHIER"
  | "KITCHEN"
  | "RIDER"
  | "CUSTOMER";

export type UserStatus = "ACTIVE" | "INACTIVE" | "SUSPENDED";

export type OrderStatus =
  | "PLACED"
  | "ACCEPTED"
  | "PREPARING"
  | "READY_FOR_PICKUP"
  | "PICKED_UP"
  | "ON_THE_WAY"
  | "DELIVERED"
  | "DELIVERY_FAILED"
  | "RETURNED_TO_RESTAURANT"
  | "CANCELLED"
  | "REJECTED"
  | "IGNORED_TEST";

export type OrderType = "DELIVERY" | "PICKUP" | "DINE_IN";
export type PaymentMethod = "CASH" | "CARD" | "WALLET" | "ONLINE";
export type PaymentStatus = "PENDING" | "PAID" | "FAILED" | "REFUNDED";
export type RiderApprovalStatus = "PENDING" | "APPROVED" | "REJECTED" | "SUSPENDED";
export type AssignmentStatus =
  | "CREATED"
  | "NOTIFIED"
  | "ACCEPTED"
  | "REJECTED"
  | "EXPIRED"
  | "CANCELLED";
export type ComplaintStatus = "OPEN" | "IN_REVIEW" | "RESOLVED" | "REJECTED";

export interface AuthUser {
  id: string;
  email: string | null;
  phone: string | null;
  role: UserRole;
  restaurantId?: string | null;
  branchId?: string | null;
  fullName?: string | null;
}

export interface LoginResponse {
  accessToken: string;
  refreshToken: string;
  user: AuthUser;
}

export interface DashboardStats {
  totalRevenue: number;
  foodRevenue: number;
  deliveryRevenue: number;
  totalGmv: number;
  deliveredOrders: number;
  activeOrders: number;
  onlineRiders: number;
  totalCustomers: number;
  ordersToday: number;
}

export interface DailyRevenuePoint {
  date: string;
  revenue: number;
  foodRevenue: number;
  deliveryRevenue: number;
}

export interface PopularItem {
  id: string;
  name: string;
  price: number;
  imageUrl?: string | null;
  description?: string | null;
  category?: { name: string } | null;
  totalSales: number;
}

/** Shape returned by the admin list endpoints ({ data, meta }). */
export interface ListResponse<T> {
  data: T[];
  meta: { page: number; limit: number; total: number; totalPages: number };
}

/** Compact order row from GET /admin/orders. */
export interface OrderListItem {
  id: string;
  orderNumber: string;
  customerName: string | null;
  customerPhone: string | null;
  status: OrderStatus;
  orderType: OrderType;
  paymentMethod: PaymentMethod;
  paymentStatus: PaymentStatus;
  grandTotal: number;
  placedAt: string;
  deliveredAt?: string | null;
  itemsSummary: string;
  riderName?: string | null;
  deliveryService?: string | null;
  trackingId?: string | null;
}

export interface OrderItem {
  id: string;
  name: string;
  unitPrice: number;
  quantity: number;
  notes?: string | null;
  lineTotal: number;
  addons?: { id: string; name: string; price: number }[];
  menuItem?: { imageUrl?: string | null } | null;
}

export interface OrderStatusHistoryEntry {
  id: string;
  status: OrderStatus;
  previousStatus?: OrderStatus | null;
  note?: string | null;
  createdAt: string;
}

export interface Order {
  id: string;
  orderNumber: string;
  status: OrderStatus;
  orderType: OrderType;
  paymentMethod: PaymentMethod;
  paymentStatus: PaymentStatus;
  customerName: string | null;
  customerPhone: string | null;
  deliveryAddress?: string | null;
  subtotal: number;
  discountAmount: number;
  taxAmount: number;
  packagingFee: number;
  deliveryFee: number;
  riderFee: number;
  grandTotal: number;
  routeDistanceKm?: number | null;
  routeEtaMinutes?: number | null;
  prepMinutes?: number | null;
  createdAt: string;
  acceptedAt?: string | null;
  deliveredAt?: string | null;
  items?: OrderItem[];
  statusHistory?: OrderStatusHistoryEntry[];
  assignment?: RiderAssignment | null;
  restaurant?: { name: string; city?: string } | null;
  customer?: { email?: string; phone?: string } | null;
  payment?: { method: string; status: string; amount: number } | null;
}

export interface RiderAssignment {
  id: string;
  status: AssignmentStatus;
  riderId: string;
  rider?: {
    id: string;
    fullName?: string | null;
    phone?: string | null;
  } | null;
  assignedAt?: string | null;
  acceptedAt?: string | null;
}

export interface AvailableRider {
  id: string;
  fullName: string | null;
  vehicleType: string | null;
  ratingAvg?: number | null;
  ratingCount?: number | null;
  isOnline: boolean;
  user: { id: string; phone: string | null };
}

export interface AppUser {
  id: string;
  email: string | null;
  phone: string | null;
  role: UserRole;
  status: UserStatus;
  createdAt: string;
  lastLoginAt?: string | null;
  customerProfile?: { fullName?: string | null; avatarUrl?: string | null } | null;
  staffProfile?: { fullName?: string | null; jobTitle?: string | null } | null;
  riderProfile?: RiderProfile | null;
  _count?: { orders: number; reviews: number };
}

export interface RiderProfile {
  id?: string;
  fullName?: string | null;
  phone?: string | null;
  vehicleType?: string | null;
  licenseNumber?: string | null;
  approvalStatus: RiderApprovalStatus;
  isOnline?: boolean;
  ratingAvg?: number | null;
}

/** Flattened row from GET /admin/users. */
export interface UserListItem {
  id: string;
  email: string | null;
  phone: string | null;
  role: UserRole;
  status: UserStatus;
  createdAt: string;
  lastLoginAt?: string | null;
  name: string;
  avatarUrl?: string | null;
  totalOrders: number;
  isOnline?: boolean | null;
  ratingAvg?: number | null;
}

export interface RiderDocument {
  id: string;
  type: string;
  url: string;
  status: "PENDING" | "APPROVED" | "REJECTED";
  uploadedAt: string;
}

/** Row from GET /admin/riders. */
export interface RiderListItem {
  id: string;
  userId: string;
  fullName: string | null;
  phone: string | null;
  email: string | null;
  isOnline: boolean;
  canReceiveOffers: boolean;
  exceptionCount30d: number;
  lastExceptionAt?: string | null;
  ratingAvg?: number | null;
  ratingCount?: number | null;
  vehicleType: string | null;
  totalDeliveries: number;
  status: UserStatus;
  approvalStatus: RiderApprovalStatus;
  documents: RiderDocument[];
}

/** Row from GET /admin/riders/pending. */
export interface PendingRider {
  id: string;
  fullName: string | null;
  phone: string | null;
  vehicleType: string | null;
  createdAt: string;
  documents: RiderDocument[];
}

export interface Addon {
  id: string;
  name: string;
  price: number;
  isActive: boolean;
}

/** Junction row from the admin menu (menuItem.addons[].addon). */
export interface MenuItemAddonLink {
  addon: Addon;
}

export interface MenuItem {
  id: string;
  categoryId: string;
  name: string;
  description?: string | null;
  price: number;
  compareAtPrice?: number | null;
  imageUrl?: string | null;
  isAvailable: boolean;
  isFeatured: boolean;
  sortOrder?: number;
  tags?: string[];
  addons?: MenuItemAddonLink[];
}

/** GET /admin/menu returns categories with nested menuItems. */
export interface MenuCategory {
  id: string;
  name: string;
  sortOrder: number;
  isActive: boolean;
  imageUrl?: string | null;
  menuItems?: MenuItem[];
}

export interface UploadResult {
  url: string;
  publicId: string;
}

export interface Banner {
  id: string;
  title: string;
  imageUrl: string;
  linkUrl?: string | null;
  sortOrder: number;
  isActive: boolean;
  startsAt?: string | null;
  endsAt?: string | null;
}

export interface Coupon {
  id: string;
  code: string;
  description?: string | null;
  discountType: "PERCENT" | "FLAT";
  discountValue: number;
  minOrderAmount?: number | null;
  maxUses?: number | null;
  usedCount: number;
  isActive: boolean;
  startsAt?: string | null;
  endsAt?: string | null;
  // Targeting
  perUserLimit?: number | null;
  newCustomersOnly?: boolean;
  targetUserId?: string | null;
  targetCustomer?: { email: string | null; phone: string | null } | null;
}

export interface RestaurantSettings {
  taxRatePercent?: number;
  packagingFee?: number;
  currency?: string;
  minOrderAmount?: number;
  autoAcceptOrders?: boolean;
  defaultPrepMinutes?: number;
  assignmentTimeoutSec?: number;
  slaAcceptSeconds?: number;
  slaPrepSeconds?: number;
  slaPickupWaitSeconds?: number;
  showTestOrdersInKitchen?: boolean;
}

export interface DeliveryFeeConfig {
  baseFee?: number;
  perKmFee?: number;
  peakHourSurcharge?: number;
  freeDeliveryThreshold?: number;
  maxDeliveryKm?: number;
}

export interface OperatingHour {
  id?: string;
  dayOfWeek: number;
  openTime: string;
  closeTime: string;
  isClosed: boolean;
}

export interface DeliveryZone {
  id: string;
  name: string;
  maxDistanceKm?: number | null;
  isActive: boolean;
}

export interface RestaurantDetail {
  id: string;
  name: string;
  description?: string | null;
  phone?: string | null;
  email?: string | null;
  logoUrl?: string | null;
  addressLine?: string | null;
  city?: string | null;
  country?: string | null;
  latitude?: number | null;
  longitude?: number | null;
  isActive: boolean;
  settings?: RestaurantSettings | null;
  deliveryFeeConfig?: DeliveryFeeConfig | null;
  operatingHours?: OperatingHour[];
}

export interface Complaint {
  id: string;
  type: "COMPLAINT" | "REFUND_REQUEST";
  status: ComplaintStatus;
  subject: string;
  description: string;
  refundAmount?: number | null;
  staffNote?: string | null;
  createdAt: string;
  order?: { orderNumber: string } | null;
  user?: { email?: string | null; phone?: string | null } | null;
}

export type ReportPeriod = "day" | "week" | "month";

export interface SalesSummary {
  period: ReportPeriod;
  orderCount: number;
  foodRevenue: number;
  deliveryRevenue: number;
  totalGmv: number;
  refundsTotal: number;
  netFoodRevenue: number;
  totalRevenue: number;
  averageOrderValue: number;
}

export interface EarningsReport {
  period: ReportPeriod;
  deliveredOrders: number;
  foodRevenue: number;
  deliveryRevenue: number;
  totalGmv: number;
  refundsTotal: number;
  netFoodRevenue: number;
  totalPaid: number;
  paidOrders: number;
}

export interface RiderPerformance {
  rider: {
    id: string;
    fullName: string | null;
    ratingAvg?: number | null;
    ratingCount?: number | null;
  };
  deliveries: number;
}

export interface CodSettlement {
  id: string;
  orderId: string;
  codCollectedAmount?: number | null;
  foodAmountRemitted?: number | null;
  deliveryFeeKept?: number | null;
  status: "PENDING" | "SETTLED";
  order: {
    orderNumber: string;
    grandTotal: number;
    deliveredAt?: string | null;
  };
  rider?: { fullName: string | null } | null;
}

export interface Paginated<T> {
  data: T[];
  total: number;
  page: number;
  limit: number;
  totalPages?: number;
}
