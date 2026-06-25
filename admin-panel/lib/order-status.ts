import type { OrderStatus } from "@/types";
import type { badgeVariants } from "@/components/ui/badge";
import type { VariantProps } from "class-variance-authority";

type BadgeVariant = VariantProps<typeof badgeVariants>["variant"];

interface StatusConfig {
  label: string;
  variant: BadgeVariant;
}

export const ORDER_STATUS_CONFIG: Record<OrderStatus, StatusConfig> = {
  PLACED: { label: "Placed", variant: "info" },
  ACCEPTED: { label: "Accepted", variant: "info" },
  PREPARING: { label: "Preparing", variant: "warning" },
  READY_FOR_PICKUP: { label: "Ready", variant: "warning" },
  PICKED_UP: { label: "Picked up", variant: "info" },
  ON_THE_WAY: { label: "On the way", variant: "info" },
  DELIVERED: { label: "Delivered", variant: "success" },
  DELIVERY_FAILED: { label: "Failed", variant: "destructive" },
  RETURNED_TO_RESTAURANT: { label: "Returned", variant: "destructive" },
  CANCELLED: { label: "Cancelled", variant: "muted" },
  REJECTED: { label: "Rejected", variant: "destructive" },
  IGNORED_TEST: { label: "Test", variant: "muted" },
};

export function orderStatusConfig(status: OrderStatus): StatusConfig {
  return ORDER_STATUS_CONFIG[status] ?? { label: status, variant: "muted" };
}

/** Active (in-progress) statuses — used for ops queues & live filtering. */
export const ACTIVE_ORDER_STATUSES: OrderStatus[] = [
  "PLACED",
  "ACCEPTED",
  "PREPARING",
  "READY_FOR_PICKUP",
  "PICKED_UP",
  "ON_THE_WAY",
];

export const ORDER_STATUS_OPTIONS: { value: OrderStatus; label: string }[] =
  Object.entries(ORDER_STATUS_CONFIG).map(([value, cfg]) => ({
    value: value as OrderStatus,
    label: cfg.label,
  }));
