// Storefront brand/contact info shaped exactly like the backend
// `GET /restaurant/slug/:slug` response (Restaurant model + operatingHours).
// Safe brand-only fallback. Contact, address and hours must come from the live API.

import type { OperatingHour } from "@/types";

export type { OperatingHour };

export interface RestaurantInfo {
  name: string;
  description: string;
  phone: string | null;
  email: string | null;
  addressLine: string | null;
  city: string | null;
  country: string | null;
  operatingHours: OperatingHour[];
}

export const RESTAURANT_INFO: RestaurantInfo = {
  name: "Wasabi Momo House",
  description:
    "Wasabi began with one idea: momo worth making a moment for. Every batch is folded by hand and steamed to order, so what reaches you is fresh, generous, and full of flavour — whether it lands at your door or you grab it on the way home.",
  phone: null,
  email: null,
  addressLine: null,
  city: null,
  country: null,
  operatingHours: [],
};

const DAY_LABELS = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"] as const;

/** "11:00" -> "11:00 AM" */
export function formatTime(hhmm: string): string {
  const [hStr, m] = hhmm.split(":");
  const h = Number(hStr);
  const period = h >= 12 ? "PM" : "AM";
  const h12 = h % 12 === 0 ? 12 : h % 12;
  return `${h12}:${m} ${period}`;
}

export interface HourRow {
  label: string;
  value: string;
  days: number[];
}

export interface OpenStatus {
  isOpen: boolean;
  /** e.g. "Open until 11:30 PM" or "Closed · Opens 11:00 AM" */
  label: string;
}

/** Derive the current open/closed state from operating hours. */
export function getOpenStatus(
  hours: OperatingHour[],
  now: Date = new Date()
): OpenStatus | null {
  if (!hours.length) return null;
  const today = hours.find((h) => h.dayOfWeek === now.getDay());
  if (!today || today.isClosed) {
    const next = [1, 2, 3, 4, 5, 6, 7]
      .map((offset) => hours.find((h) => h.dayOfWeek === (now.getDay() + offset) % 7))
      .find((h) => h && !h.isClosed);
    return {
      isOpen: false,
      label: next ? `Closed · Opens ${formatTime(next.openTime)}` : "Closed today",
    };
  }
  const mins = now.getHours() * 60 + now.getMinutes();
  const [oh, om] = today.openTime.split(":").map(Number);
  const [ch, cm] = today.closeTime.split(":").map(Number);
  const open = oh * 60 + om;
  let close = ch * 60 + cm;
  if (close <= open) close += 24 * 60; // past-midnight close
  const isOpen = mins >= open && mins < close;
  return {
    isOpen,
    label: isOpen
      ? `Open until ${formatTime(today.closeTime)}`
      : mins < open
        ? `Closed · Opens ${formatTime(today.openTime)}`
        : "Closed for today",
  };
}

/** Collapse consecutive days that share the same hours into ranges. */
export function groupedHours(hours: OperatingHour[]): HourRow[] {
  const sorted = [...hours].sort((a, b) => a.dayOfWeek - b.dayOfWeek);
  const rows: HourRow[] = [];

  for (const h of sorted) {
    const value = h.isClosed
      ? "Closed"
      : `${formatTime(h.openTime)} – ${formatTime(h.closeTime)}`;
    const last = rows[rows.length - 1];
    const contiguous =
      last && last.value === value && last.days[last.days.length - 1] === h.dayOfWeek - 1;

    if (contiguous) {
      last.days.push(h.dayOfWeek);
      last.label =
        last.days.length === 1
          ? DAY_LABELS[last.days[0]]
          : `${DAY_LABELS[last.days[0]]} – ${DAY_LABELS[last.days[last.days.length - 1]]}`;
    } else {
      rows.push({ label: DAY_LABELS[h.dayOfWeek], value, days: [h.dayOfWeek] });
    }
  }
  return rows;
}
