"use client";

import {
  Area,
  AreaChart,
  CartesianGrid,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";

import { formatCompact, formatCurrency } from "@/lib/utils";
import type { DailyRevenuePoint } from "@/types";

interface RevenueChartProps {
  data: DailyRevenuePoint[];
}

function shortDate(value: string) {
  const d = new Date(value);
  return d.toLocaleDateString("en-US", { month: "short", day: "numeric" });
}

interface TooltipItem {
  name?: string;
  value?: number | string;
  color?: string;
}

function ChartTooltip({
  active,
  payload,
  label,
}: {
  active?: boolean;
  payload?: TooltipItem[];
  label?: string;
}) {
  if (!active || !payload?.length) return null;
  return (
    <div className="bg-popover rounded-lg border px-3 py-2 text-sm shadow-md">
      <p className="mb-1 font-medium">{label ? shortDate(label) : ""}</p>
      {payload.map((entry) => (
        <div key={entry.name} className="flex items-center gap-2">
          <span
            className="size-2 rounded-full"
            style={{ backgroundColor: entry.color }}
          />
          <span className="text-muted-foreground capitalize">{entry.name}</span>
          <span className="ml-auto font-medium tabular-nums">
            {formatCurrency(Number(entry.value))}
          </span>
        </div>
      ))}
    </div>
  );
}

export function RevenueChart({ data }: RevenueChartProps) {
  return (
    <ResponsiveContainer width="100%" height={280}>
      <AreaChart data={data} margin={{ top: 8, right: 8, left: 0, bottom: 0 }}>
        <defs>
          <linearGradient id="foodFill" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor="var(--chart-1)" stopOpacity={0.35} />
            <stop offset="100%" stopColor="var(--chart-1)" stopOpacity={0} />
          </linearGradient>
          <linearGradient id="deliveryFill" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor="var(--chart-2)" stopOpacity={0.3} />
            <stop offset="100%" stopColor="var(--chart-2)" stopOpacity={0} />
          </linearGradient>
        </defs>
        <CartesianGrid
          strokeDasharray="3 3"
          vertical={false}
          stroke="var(--border)"
        />
        <XAxis
          dataKey="date"
          tickFormatter={shortDate}
          tickLine={false}
          axisLine={false}
          tick={{ fontSize: 12, fill: "var(--muted-foreground)" }}
          dy={8}
        />
        <YAxis
          tickFormatter={(v) => formatCompact(v)}
          tickLine={false}
          axisLine={false}
          tick={{ fontSize: 12, fill: "var(--muted-foreground)" }}
          width={48}
        />
        <Tooltip content={<ChartTooltip />} cursor={{ stroke: "var(--border)" }} />
        <Area
          type="monotone"
          dataKey="foodRevenue"
          name="food"
          stroke="var(--chart-1)"
          strokeWidth={2}
          fill="url(#foodFill)"
        />
        <Area
          type="monotone"
          dataKey="deliveryRevenue"
          name="delivery"
          stroke="var(--chart-2)"
          strokeWidth={2}
          fill="url(#deliveryFill)"
        />
      </AreaChart>
    </ResponsiveContainer>
  );
}
