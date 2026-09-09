"use client";

import { ChevronsUpDown, Store } from "lucide-react";

import {
  Tooltip,
  TooltipContent,
  TooltipTrigger,
} from "@/components/ui/tooltip";
import { cn } from "@/lib/utils";

/**
 * Branch switcher — intentionally a disabled stub for the single-branch MVP.
 * Query hooks already accept an optional `branchId`, so wiring this up later
 * (once multiple branches are live) is non-breaking.
 */
export function BranchSwitcher({ className }: { className?: string }) {
  return (
    <Tooltip>
      <TooltipTrigger asChild>
        <button
          type="button"
          disabled
          aria-label="Branch (single branch active)"
          className={cn(
            "flex items-center gap-2 rounded-md border bg-card px-2.5 py-1.5 text-sm opacity-90",
            "cursor-not-allowed",
            className
          )}
        >
          <Store className="text-muted-foreground size-4" />
          <span className="max-w-[10rem] truncate font-medium">Main Branch</span>
          <ChevronsUpDown className="text-muted-foreground size-3.5" />
        </button>
      </TooltipTrigger>
      <TooltipContent>Multi-branch switching arrives in a later release</TooltipContent>
    </Tooltip>
  );
}
