import * as React from "react";

import { cn } from "@/lib/utils";

/**
 * --cream-100 is a fixed cream, not a theme token: as a field background it
 * stayed white in dark mode under near-white text. Surfaces here follow the
 * theme so the control is readable in both.
 */
export const controlBase =
  "w-full rounded-xl border border-[var(--border)] bg-[var(--surface)] text-[15px] text-[var(--foreground)] outline-none " +
  "transition-[border-color,box-shadow,background-color] duration-200 ease-out " +
  "placeholder:text-[var(--foreground-mute)] " +
  "hover:border-[var(--foreground-mute)] " +
  "focus-visible:border-[var(--brand)] focus-visible:shadow-[0_0_0_4px_color-mix(in_srgb,var(--brand)_16%,transparent)] " +
  "disabled:cursor-not-allowed disabled:opacity-50";

const Input = React.forwardRef<
  HTMLInputElement,
  React.InputHTMLAttributes<HTMLInputElement>
>(({ className, type, ...props }, ref) => (
  <input type={type} ref={ref} className={cn(controlBase, "h-12 px-3.5", className)} {...props} />
));
Input.displayName = "Input";

export { Input };
