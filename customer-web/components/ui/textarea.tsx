import * as React from "react";

import { controlBase } from "@/components/ui/input";
import { cn } from "@/lib/utils";

const Textarea = React.forwardRef<
  HTMLTextAreaElement,
  React.TextareaHTMLAttributes<HTMLTextAreaElement>
>(({ className, rows = 4, ...props }, ref) => (
  <textarea
    ref={ref}
    rows={rows}
    className={cn(controlBase, "resize-y px-3.5 py-3 leading-6", className)}
    {...props}
  />
));
Textarea.displayName = "Textarea";

export { Textarea };
