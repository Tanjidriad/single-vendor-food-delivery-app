import type { LucideIcon } from "lucide-react";
import { ArrowDownRight, ArrowUpRight } from "lucide-react";

import { Card } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { cn } from "@/lib/utils";

interface KpiCardProps {
  label: string;
  value: string | number;
  icon: LucideIcon;
  hint?: string;
  trend?: { value: number; positive?: boolean };
  accent?: "primary" | "success" | "info" | "warning";
  loading?: boolean;
}

const accentClasses: Record<NonNullable<KpiCardProps["accent"]>, string> = {
  primary: "bg-primary/10 text-primary",
  success: "bg-success/12 text-success",
  info: "bg-info/12 text-info",
  warning: "bg-warning/15 text-warning-foreground dark:text-warning",
};

export function KpiCard({
  label,
  value,
  icon: Icon,
  hint,
  trend,
  accent = "primary",
  loading,
}: KpiCardProps) {
  return (
    <Card className="gap-0 p-5">
      <div className="flex items-start justify-between">
        <div className="space-y-1">
          <p className="text-muted-foreground text-sm font-medium">{label}</p>
          {loading ? (
            <Skeleton className="mt-1.5 h-8 w-24" />
          ) : (
            <p className="text-3xl font-semibold tracking-tight tabular-nums">
              {value}
            </p>
          )}
        </div>
        <div
          className={cn(
            "flex size-10 items-center justify-center rounded-lg",
            accentClasses[accent]
          )}
        >
          <Icon className="size-5" />
        </div>
      </div>
      {(hint || trend) && !loading && (
        <div className="mt-3 flex items-center gap-2 text-sm">
          {trend && (
            <span
              className={cn(
                "flex items-center gap-0.5 font-medium",
                trend.positive ? "text-success" : "text-destructive"
              )}
            >
              {trend.positive ? (
                <ArrowUpRight className="size-3.5" />
              ) : (
                <ArrowDownRight className="size-3.5" />
              )}
              {Math.abs(trend.value)}%
            </span>
          )}
          {hint && <span className="text-muted-foreground">{hint}</span>}
        </div>
      )}
    </Card>
  );
}
