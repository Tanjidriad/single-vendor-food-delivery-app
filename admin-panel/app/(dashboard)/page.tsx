"use client";

import {
  Bike,
  Banknote,
  ClipboardList,
  ShoppingBag,
  TrendingUp,
  Users,
} from "lucide-react";

import { PageHeader } from "@/components/common/page-header";
import { ErrorState } from "@/components/common/error-state";
import { KpiCard } from "@/components/dashboard/kpi-card";
import { RevenueChart } from "@/components/dashboard/revenue-chart";
import { RecentOrders } from "@/components/dashboard/recent-orders";
import { TopItems } from "@/components/dashboard/top-items";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import {
  useDailyRevenue,
  useDashboardStats,
  usePopularItems,
  useRecentOrders,
} from "@/lib/api/queries/dashboard";
import { formatCurrency, formatNumber } from "@/lib/utils";

export default function DashboardPage() {
  const stats = useDashboardStats();
  const revenue = useDailyRevenue(7);
  const recentOrders = useRecentOrders(6);
  const popularItems = usePopularItems(5);

  const s = stats.data;

  return (
    <div className="space-y-6">
      <PageHeader
        title="Dashboard"
        description="Today at a glance across your restaurant."
      />

      {stats.isError ? (
        <ErrorState
          message="Couldn't load dashboard metrics."
          onRetry={() => stats.refetch()}
        />
      ) : (
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">
          <KpiCard
            label="Total revenue"
            value={formatCurrency(s?.totalRevenue ?? 0)}
            icon={Banknote}
            accent="success"
            hint="Delivered orders"
            loading={stats.isLoading}
          />
          <KpiCard
            label="Active orders"
            value={formatNumber(s?.activeOrders ?? 0)}
            icon={ShoppingBag}
            accent="primary"
            hint="In progress now"
            loading={stats.isLoading}
          />
          <KpiCard
            label="Orders today"
            value={formatNumber(s?.ordersToday ?? 0)}
            icon={ClipboardList}
            accent="info"
            hint="Placed since midnight"
            loading={stats.isLoading}
          />
          <KpiCard
            label="Riders online"
            value={formatNumber(s?.onlineRiders ?? 0)}
            icon={Bike}
            accent="warning"
            hint="Available to dispatch"
            loading={stats.isLoading}
          />
        </div>
      )}

      <div className="grid grid-cols-1 gap-4 xl:grid-cols-3">
        <Card className="xl:col-span-2">
          <CardHeader className="border-b">
            <CardTitle>Revenue</CardTitle>
            <CardDescription>
              Food vs. delivery revenue over the last 7 days
            </CardDescription>
          </CardHeader>
          <CardContent>
            {revenue.isLoading ? (
              <Skeleton className="h-[280px] w-full" />
            ) : revenue.isError ? (
              <ErrorState
                className="my-4"
                message="Couldn't load revenue data."
                onRetry={() => revenue.refetch()}
              />
            ) : (
              <RevenueChart data={revenue.data ?? []} />
            )}
            <div className="mt-4 flex items-center gap-6 text-sm">
              <Legend color="var(--chart-1)" label="Food revenue" />
              <Legend color="var(--chart-2)" label="Delivery revenue" />
            </div>
          </CardContent>
        </Card>

        <SecondaryStats
          gmv={s?.totalGmv ?? 0}
          delivered={s?.deliveredOrders ?? 0}
          customers={s?.totalCustomers ?? 0}
          deliveryRevenue={s?.deliveryRevenue ?? 0}
          loading={stats.isLoading}
        />
      </div>

      <div className="grid grid-cols-1 gap-4 xl:grid-cols-3">
        <div className="xl:col-span-2">
          <RecentOrders
            orders={recentOrders.data}
            loading={recentOrders.isLoading}
          />
        </div>
        <TopItems items={popularItems.data} loading={popularItems.isLoading} />
      </div>
    </div>
  );
}

function Legend({ color, label }: { color: string; label: string }) {
  return (
    <span className="text-muted-foreground flex items-center gap-2">
      <span className="size-2.5 rounded-full" style={{ backgroundColor: color }} />
      {label}
    </span>
  );
}

function SecondaryStats({
  gmv,
  delivered,
  customers,
  deliveryRevenue,
  loading,
}: {
  gmv: number;
  delivered: number;
  customers: number;
  deliveryRevenue: number;
  loading?: boolean;
}) {
  const rows = [
    { icon: TrendingUp, label: "Gross merchandise value", value: formatCurrency(gmv) },
    { icon: ClipboardList, label: "Delivered orders", value: formatNumber(delivered) },
    { icon: Banknote, label: "Delivery revenue", value: formatCurrency(deliveryRevenue) },
    { icon: Users, label: "Registered customers", value: formatNumber(customers) },
  ];
  return (
    <Card>
      <CardHeader className="border-b">
        <CardTitle>Summary</CardTitle>
        <CardDescription>Lifetime performance</CardDescription>
      </CardHeader>
      <CardContent className="space-y-1">
        {rows.map((row) => (
          <div
            key={row.label}
            className="flex items-center gap-3 rounded-lg px-1 py-2.5"
          >
            <div className="bg-muted text-muted-foreground flex size-9 items-center justify-center rounded-lg">
              <row.icon className="size-4.5" />
            </div>
            <span className="text-muted-foreground text-sm">{row.label}</span>
            {loading ? (
              <Skeleton className="ml-auto h-5 w-16" />
            ) : (
              <span className="ml-auto font-semibold tabular-nums">
                {row.value}
              </span>
            )}
          </div>
        ))}
      </CardContent>
    </Card>
  );
}
