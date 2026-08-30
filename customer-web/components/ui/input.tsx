import * as React from "react";

import { cn } from "@/lib/utils";

const Input = React.forwardRef<
  HTMLInputElement,
  React.InputHTMLAttributes<HTMLInputElement>
>(({ className, type, ...props }, ref) => {
  return (
    <input
      type={type}
      ref={ref}
      className={cn(
        "flex h-[54px] w-full rounded-none border border-[var(--border)] bg-[var(--cream-100)] px-4 text-[15px] text-[var(--foreground)] outline-none transition-colors placeholder:text-[var(--foreground-mute)] focus-visible:border-[var(--brand)] focus-visible:ring-4 focus-visible:ring-[color-mix(in_srgb,var(--brand)_18%,transparent)] disabled:cursor-not-allowed disabled:opacity-50",
        className
      )}
      {...props}
    />
  );
});
Input.displayName = "Input";

export { Input };
