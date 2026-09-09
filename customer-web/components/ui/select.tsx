import * as React from "react";

import { controlBase } from "@/components/ui/input";
import { cn } from "@/lib/utils";

/**
 * Native select. On a phone it opens the OS picker, which beats any custom
 * listbox for one-handed ordering.
 */
const Select = React.forwardRef<
  HTMLSelectElement,
  React.SelectHTMLAttributes<HTMLSelectElement>
>(({ className, children, ...props }, ref) => (
  <div className="relative">
    <select
      ref={ref}
      className={cn(controlBase, "h-12 appearance-none pl-3.5 pr-11", className)}
      {...props}
    >
      {children}
    </select>
    <svg
      aria-hidden
      width="16"
      height="16"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      className="pointer-events-none absolute right-3.5 top-1/2 -translate-y-1/2 text-[var(--foreground-mute)]"
    >
      <path d="M6 9l6 6 6-6" />
    </svg>
  </div>
));
Select.displayName = "Select";

export { Select };
