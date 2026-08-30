import * as React from "react";
import { Slot } from "@radix-ui/react-slot";
import { cva, type VariantProps } from "class-variance-authority";

import { cn } from "@/lib/utils";

const buttonVariants = cva(
  "inline-flex items-center justify-center gap-2 whitespace-nowrap font-semibold transition-[background-color,transform,box-shadow] duration-[140ms] ease-[cubic-bezier(0.22,1,0.36,1)] focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-[color-mix(in_srgb,var(--brand)_28%,transparent)] active:scale-[0.98] disabled:pointer-events-none disabled:opacity-50 select-none",
  {
    variants: {
      variant: {
        primary:
          "bg-[var(--brand)] text-white hover:bg-[var(--ink)] active:bg-[var(--brand-active)]",
        dark: "bg-[var(--ink)] text-[var(--on-ink)] hover:bg-[var(--charcoal-800)]",
        light:
          "bg-[var(--cream-100)] text-[var(--charcoal-900)] border border-[var(--border)] hover:bg-[var(--cream-200)]",
        ghost:
          "bg-transparent text-[var(--foreground)] hover:bg-[var(--surface-sunken)]",
      },
      size: {
        default: "h-[52px] px-6 rounded-none text-[13px] font-black uppercase tracking-[0.06em]",
        sm: "h-11 px-4 rounded-none text-xs font-black uppercase tracking-[0.06em]",
        lg: "h-[56px] px-8 rounded-none text-sm font-black uppercase tracking-[0.06em]",
        icon: "h-11 w-11 rounded-none",
      },
    },
    defaultVariants: { variant: "primary", size: "default" },
  }
);

export interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof buttonVariants> {
  asChild?: boolean;
}

const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant, size, asChild = false, ...props }, ref) => {
    const Comp = asChild ? Slot : "button";
    return (
      <Comp
        className={cn(buttonVariants({ variant, size, className }))}
        ref={ref}
        {...props}
      />
    );
  }
);
Button.displayName = "Button";

export { Button, buttonVariants };
