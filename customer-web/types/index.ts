export type UserRole =
  | "CUSTOMER"
  | "OWNER"
  | "MANAGER"
  | "CASHIER"
  | "KITCHEN"
  | "RIDER"
  | "ADMIN";

export interface AuthUser {
  id: string;
  email: string | null;
  phone: string | null;
  role: UserRole;
  fullName: string | null;
}

export interface LoginResponse {
  user: AuthUser;
}

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
  | "REJECTED";

export interface MenuAddon {
  id: string;
  name: string;
  price: number;
}

export interface MenuItem {
  id: string;
  name: string;
  description?: string | null;
  price: number;
  imageUrl?: string | null;
  isAvailable?: boolean;
  isFeatured?: boolean;
  addons?: MenuAddon[];
}

export interface MenuCategory {
  id: string;
  name: string;
  items: MenuItem[];
}

export interface OperatingHour {
  dayOfWeek: number; // 0 = Sunday … 6 = Saturday
  openTime: string; // "HH:mm"
  closeTime: string; // "HH:mm"
  isClosed: boolean;
}

export interface Restaurant {
  id: string;
  name: string;
  slug: string;
  description?: string | null;
  phone?: string | null;
  email?: string | null;
  logoUrl?: string | null;
  latitude?: number;
  longitude?: number;
  addressLine?: string | null;
  city?: string | null;
  country?: string | null;
  operatingHours?: OperatingHour[];
  settings?: {
    taxRatePercent: number;
    packagingFee: number;
    currency: string;
    minOrderAmount: number;
    defaultPrepMinutes?: number;
  } | null;
}

export interface Banner {
  id: string;
  title: string;
  imageUrl: string;
  linkUrl?: string | null;
  sortOrder: number;
}

export interface Review {
  id: string;
  rating: number;
  comment?: string | null;
  createdAt: string;
  authorName: string;
  avatarUrl?: string | null;
}

export interface CartLine {
  itemId: string;
  name: string;
  price: number;
  quantity: number;
  imageUrl?: string | null;
  addons: MenuAddon[];
}

export type OrderType = "DELIVERY" | "PICKUP";
export type PaymentMethod = "COD" | "ONLINE" | "WALLET";
export type PaymentStatus = "PENDING" | "PAID" | "FAILED" | "REFUNDED";

export interface PaymentInitiation {
  orderId: string;
  gateway: string;
  amount: number;
  currency: string;
  status: PaymentStatus;
  paymentId: string;
  checkoutUrl: string;
  callbackUrl: string;
}

export interface PaymentExecution {
  orderId: string;
  gateway?: string;
  status: PaymentStatus;
  transactionId?: string;
  paidAt?: string;
  message?: string;
}
export type AddressLabel = "HOME" | "OFFICE" | "OTHER";

export interface Address {
  id: string;
  label: AddressLabel;
  line1: string;
  line2?: string | null;
  city?: string | null;
  postalCode?: string | null;
  latitude: number;
  longitude: number;
  instructions?: string | null;
  isDefault: boolean;
}

export interface DeliveryQuote {
  distanceKm: number;
  etaMinutes: number;
  deliveryFee: number;
  riderFee: number;
  routeSource: string;
  currency: string;
}

export interface CouponValidation {
  valid: boolean;
  couponId: string;
  code: string;
  discount: number;
}

export interface PublicCoupon {
  id: string;
  code: string;
  description?: string | null;
  discountType: "PERCENT" | "FIXED";
  discountValue: number;
  minOrderAmount?: number | null;
  endsAt?: string | null;
}

export interface OrderItemAddon {
  id?: string;
  name: string;
  price: number;
}

export interface OrderItem {
  id: string;
  name: string;
  unitPrice: number;
  quantity: number;
  lineTotal: number;
  notes?: string | null;
  addons: OrderItemAddon[];
  menuItem?: { imageUrl?: string | null } | null;
}

export interface OrderStatusEvent {
  status: OrderStatus;
  createdAt: string;
  note?: string | null;
}

export interface RiderLocation {
  orderId?: string;
  latitude: number;
  longitude: number;
  recordedAt?: string;
  heading?: number;
}

export type ComplaintType = "COMPLAINT" | "REFUND_REQUEST";
export type ComplaintStatus = "OPEN" | "IN_REVIEW" | "RESOLVED" | "REJECTED";

export interface Favorite {
  id: string;
  menuItem: MenuItem;
  createdAt?: string;
}

export interface Complaint {
  id: string;
  orderId: string;
  type: ComplaintType;
  subject: string;
  description: string;
  status: ComplaintStatus;
  refundAmount?: number | null;
  resolutionNote?: string | null;
  createdAt: string;
  order?: {
    orderNumber?: string;
    dailySerial?: number | null;
  } | null;
}

export interface AppNotification {
  id: string;
  title: string;
  body?: string | null;
  type?: string | null;
  data?: Record<string, unknown> | null;
  orderId?: string | null;
  readAt?: string | null;
  createdAt: string;
}

export interface Order {
  id: string;
  orderNumber: string;

  dailySerial?: number | null;
  status: OrderStatus;
  orderType: OrderType;
  paymentMethod: PaymentMethod;
  paymentStatus: PaymentStatus;
  customerName: string;
  customerPhone: string;
  deliveryAddress?: string | null;
  deliveryLat?: number | null;
  deliveryLng?: number | null;
  deliveryNote?: string | null;
  deliveryOtp?: string | null;
  deliveryService?: string | null;
  subtotal: number;
  discountAmount: number;
  taxAmount: number;
  packagingFee: number;
  deliveryFee: number;
  grandTotal: number;
  routeEtaMinutes?: number | null;
  prepMinutes?: number | null;
  placedAt: string;
  createdAt: string;
  cancelledReason?: string | null;
  items: OrderItem[];
  statusHistory?: OrderStatusEvent[];
  restaurant?: {
    id: string;
    name: string;
    latitude?: number;
    longitude?: number;
    addressLine?: string | null;
  } | null;
  assignment?: {
    rider?: {
      user?: { phone?: string | null } | null;
      locations?: RiderLocation[];
    } | null;
  } | null;
}
