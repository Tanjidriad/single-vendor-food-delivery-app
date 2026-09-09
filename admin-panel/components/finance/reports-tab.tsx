"use client";

import { useState } from "react";
import {
  Banknote,
  Bike,
  Receipt,
  ShoppingBag,
  Star,
  TrendingUp,
} from "lucide-react";

import { KpiCard } from "@/components/dashboard/kpi-card";
import { ErrorState } from "@/components/common/error-state";
import { EmptyState } from "@/components/common/empty-state";
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  useEarningsReport,
  useRiderPerformance,
  useSalesReport,
} from "@/lib/api/queries/finance";
import { formatCurrency, formatNumber } from "@/lib/utils";
import type { ReportPeriod } from "@/types";

const PERIODS: { value: ReportPeriod; label: string }[] = [
  { value: "day", label: "Today" },
  { value: "week", label: "This week" },
  { value: "month", label: "This month" },
];

export function ReportsTab() {
  const [period, setPeriod] = useState<ReportPeriod>("week");
  const sales = useSalesReport(period);
  const earnings = useEarningsReport(period);
  const riders = useRiderPerformance();

  const s = sales.data;

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <p className="text-muted-foreground text-sm">
          Performance for the selected period.
        </p>
        <Select value={period} onValueChange={(v) => setPeriod(v as ReportPeriod)}>
          <SelectTrigger className="w-40" size="sm">
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            {PERIODS.map((p) => (
              <SelectItem key={p.value} value={p.value}>
                {p.label}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      {sales.isError ? (
        <ErrorState message="Couldn't load reports." onRetry={() => sales.refetch()} />
      ) : (
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">
          <KpiCard
            label="Net revenue"
            value={formatCurrency(s?.netFoodRevenue ?? 0)}
            icon={Banknote}
            accent="success"
            loading={sales.isLoading}
          />
          <KpiCard
            label="Orders"
            value={formatNumber(s?.orderCount ?? 0)}
            icon={ShoppingBag}
            accent="primary"
            loading={sales.isLoading}
          />
          <KpiCard
            label="Avg order value"
            value={formatCurrency(s?.averageOrderValue ?? 0)}
            icon={TrendingUp}
            accent="info"
            loading={sales.isLoading}
          />
          <KpiCard
            label="Refunds"
            value={formatCurrency(s?.refundsTotal ?? 0)}
            icon={Receipt}
            accent="warning"
            loading={sales.isLoading}
          />
        </div>
      )}

      <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
        <Card>
          <CardHeader className="border-b">
            <CardTitle>Revenue breakdown</CardTitle>
          </CardHeader>
          <CardContent className="space-y-1 pt-2">
            {earnings.isLoading ? (
              <div className="space-y-2 py-2">
                {Array.from({ length: 4 }).map((_, i) => (
                  <Skeleton key={i} className="h-6 w-full" />
                ))}
              </div>
            ) : (
              <>
                <BreakdownRow label="Food revenue" value={earnings.data?.foodRevenue} />
                <BreakdownRow
                  label="Delivery revenue"
                  value={earnings.data?.deliveryRevenue}
                />
                <BreakdownRow label="Refunds" value={-(earnings.data?.refundsTotal ?? 0)} />
                <div className="border-t pt-2">
                  <BreakdownRow
                    label="Gross merchandise value"
                    value={earnings.data?.totalGmv}
                    strong
                  />
                </div>
              </>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="border-b">
            <CardTitle>Top riders</CardTitle>
          </CardHeader>
          <CardContent className="px-2">
            {riders.isLoading ? (
              <div className="space-y-2 p-2">
                {Array.from({ length: 4 }).map((_, i) => (
                  <Skeleton key={i} className="h-10 w-full" />
                ))}
              </div>
            ) : !riders.data?.length ? (
              <EmptyState
                icon={Bike}
                title="No deliveries yet"
                className="border-0"
              />
            ) : (
              <ul className="space-y-0.5">
                {riders.data.slice(0, 6).map((r, i) => (
                  <li
                    key={r.rider.id}
                    className="flex items-center gap-3 rounded-lg px-3 py-2"
                  >
                    <span className="bg-muted text-muted-foreground flex size-6 items-center justify-center rounded-md text-xs font-semibold">
                      {i + 1}
                    </span>
                    <span className="flex-1 truncate font-medium">
                      {r.rider.fullName || "Rider"}
                    </span>
                    {r.rider.ratingAvg != null && (
                      <span className="text-muted-foreground flex items-center gap-0.5 text-xs">
                        <Star className="size-3 fill-amber-400 text-amber-400" />
                        {r.rider.ratingAvg.toFixed(1)}
                      </span>
                    )}
                    <span className="tabular-nums text-sm font-medium">
                      {r.deliveries} runs
                    </span>
                  </li>
                ))}
              </ul>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  );
}

function BreakdownRow({
  label,
  value,
  strong,
}: {
  label: string;
  value?: number;
  strong?: boolean;
}) {
  return (
    <div
      className={`flex items-center justify-between py-1.5 ${strong ? "font-semibold" : "text-muted-foreground"}`}
    >
      <span>{label}</span>
      <span className="tabular-nums">{formatCurrency(value ?? 0)}</span>
    </div>
  );
}
