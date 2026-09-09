"use client";

import { useState } from "react";
import { AlertTriangle, PackageX, Truck } from "lucide-react";

import { PageHeader } from "@/components/common/page-header";
import { ErrorState } from "@/components/common/error-state";
import { EmptyState } from "@/components/common/empty-state";
import { OrderDetailSheet } from "@/components/orders/order-detail-sheet";
import { Badge } from "@/components/ui/badge";
import { Card } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { useOpsQueues } from "@/lib/api/queries/ops";
import { formatCurrency, timeAgo } from "@/lib/utils";
import type { Order } from "@/types";

export default function OperationsPage() {
  const { data, isLoading, isError, refetch } = useOpsQueues();
  const [openId, setOpenId] = useState<string | null>(null);

  return (
    <div className="space-y-6">
      <PageHeader
        title="Live operations"
        description="Orders that need attention — in transit, failed, or returned."
      />

      {isError ? (
        <ErrorState message="Couldn't load operations." onRetry={() => refetch()} />
      ) : (
        <div className="grid grid-cols-1 gap-4 lg:grid-cols-3">
          <OpsColumn
            title="On the way"
            icon={Truck}
            tone="info"
            orders={data?.stuckDeliveries}
            loading={isLoading}
            onOpen={setOpenId}
            emptyText="No deliveries in transit."
          />
          <OpsColumn
            title="Failed deliveries"
            icon={AlertTriangle}
            tone="destructive"
            orders={data?.failedDeliveries}
            loading={isLoading}
            onOpen={setOpenId}
            emptyText="No failed deliveries. 🎉"
          />
          <OpsColumn
            title="Returned to restaurant"
            icon={PackageX}
            tone="warning"
            orders={data?.returnedOrders}
            loading={isLoading}
            onOpen={setOpenId}
            emptyText="Nothing returned."
          />
        </div>
      )}

      <OrderDetailSheet
        orderId={openId}
        open={!!openId}
        onOpenChange={(o) => !o && setOpenId(null)}
      />
    </div>
  );
}

function OpsColumn({
  title,
  icon: Icon,
  tone,
  orders,
  loading,
  onOpen,
  emptyText,
}: {
  title: string;
  icon: React.ComponentType<{ className?: string }>;
  tone: "info" | "destructive" | "warning";
  orders?: Order[];
  loading?: boolean;
  onOpen: (id: string) => void;
  emptyText: string;
}) {
  const toneClass =
    tone === "destructive"
      ? "bg-destructive/10 text-destructive"
      : tone === "warning"
        ? "bg-warning/15 text-warning-foreground dark:text-warning"
        : "bg-info/12 text-info";

  return (
    <div className="space-y-3">
      <div className="flex items-center gap-2">
        <div className={`flex size-7 items-center justify-center rounded-md ${toneClass}`}>
          <Icon className="size-4" />
        </div>
        <h2 className="font-semibold">{title}</h2>
        <Badge variant="muted" className="ml-auto">
          {loading ? "…" : (orders?.length ?? 0)}
        </Badge>
      </div>

      <div className="space-y-2">
        {loading ? (
          Array.from({ length: 2 }).map((_, i) => (
            <Skeleton key={i} className="h-20 w-full rounded-xl" />
          ))
        ) : !orders?.length ? (
          <EmptyState title={emptyText} className="py-8" />
        ) : (
          orders.map((order) => (
            <Card
              key={order.id}
              onClick={() => onOpen(order.id)}
              className="hover:border-primary/40 cursor-pointer gap-2 p-3.5 transition-colors"
            >
              <div className="flex items-center justify-between">
                <span className="font-medium">#{order.orderNumber}</span>
                <span className="tabular-nums text-sm font-medium">
                  {formatCurrency(order.grandTotal)}
                </span>
              </div>
              <p className="text-muted-foreground truncate text-sm">
                {order.customerName || "Guest"} · {order.customerPhone || "—"}
              </p>
              <div className="flex items-center justify-between">
                <span className="text-muted-foreground text-xs">
                  {order.assignment?.rider?.fullName
                    ? `Rider: ${order.assignment.rider.fullName}`
                    : "Unassigned"}
                </span>
                <span className="text-muted-foreground text-xs">
                  {timeAgo(order.createdAt)}
                </span>
              </div>
            </Card>
          ))
        )}
      </div>
    </div>
  );
}
