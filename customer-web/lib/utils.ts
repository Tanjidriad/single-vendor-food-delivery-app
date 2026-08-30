import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

/** Format an amount in BDT (Bangladeshi Taka). */
export function formatTk(amount: number): string {
  return `৳${Math.round(amount).toLocaleString("en-BD")}`;
}
