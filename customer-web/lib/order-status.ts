import type { OrderStatus, OrderType } from "@/types";

export const STATUS_LABELS: Record<OrderStatus, string> = {
  PLACED: "Order placed",
  ACCEPTED: "Accepted",
  PREPARING: "Preparing",
  READY_FOR_PICKUP: "Ready",
  PICKED_UP: "Picked up",
  ON_THE_WAY: "On the way",
  DELIVERED: "Delivered",
  DELIVERY_FAILED: "Delivery failed",
  RETURNED_TO_RESTAURANT: "Returned",
  CANCELLED: "Cancelled",
  REJECTED: "Rejected",
};

export const TERMINAL_STATUSES: OrderStatus[] = [
  "DELIVERED",
  "DELIVERY_FAILED",
  "RETURNED_TO_RESTAURANT",
  "CANCELLED",
  "REJECTED",
];

export function isTerminal(status: OrderStatus): boolean {
  return TERMINAL_STATUSES.includes(status);
}

export function isCancelledLike(status: OrderStatus): boolean {
  return status === "CANCELLED" || status === "REJECTED";
}

/** Ordered progress steps for the tracker, tailored to delivery vs pickup. */
export function progressSteps(orderType: OrderType): {
  status: OrderStatus;
  label: string;
}[] {
  const common: OrderStatus[] = ["PLACED", "ACCEPTED", "PREPARING"];
  const tail: OrderStatus[] =
    orderType === "PICKUP"
      ? ["READY_FOR_PICKUP", "PICKED_UP"]
      : ["READY_FOR_PICKUP", "PICKED_UP", "ON_THE_WAY", "DELIVERED"];
  return [...common, ...tail].map((status) => ({
    status,
    label:
      status === "PICKED_UP"
        ? "Collected"
        : STATUS_LABELS[status],
  }));
}

/** Index of the current status within the progress steps (-1 if not present). */
export function currentStepIndex(
  status: OrderStatus,
  orderType: OrderType
): number {
  return progressSteps(orderType).findIndex((s) => s.status === status);
}

/** Whether the customer can still cancel (before the kitchen commits). */
export function canCancel(status: OrderStatus): boolean {
  return status === "PLACED" || status === "ACCEPTED";
}
