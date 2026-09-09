"use client";

import Link from "next/link";
import { ArrowRight } from "lucide-react";

import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardAction,
  CardHeader,
  CardTitle,
  CardContent,
} from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { EmptyState } from "@/components/common/empty-state";
import { orderStatusConfig } from "@/lib/order-status";
import { formatCurrency, timeAgo } from "@/lib/utils";
import type { OrderListItem } from "@/types";

export function RecentOrders({
  orders,
  loading,
}: {
  orders?: OrderListItem[];
  loading?: boolean;
}) {
  return (
    <Card>
      <CardHeader className="border-b">
        <CardTitle>Recent orders</CardTitle>
        <CardAction>
          <Button asChild variant="ghost" size="sm">
            <Link href="/orders">
              View all <ArrowRight className="size-4" />
            </Link>
          </Button>
        </CardAction>
      </CardHeader>
      <CardContent className="px-2">
        {loading ? (
          <div className="space-y-1 p-2">
            {Array.from({ length: 5 }).map((_, i) => (
              <Skeleton key={i} className="h-14 w-full" />
            ))}
          </div>
        ) : !orders?.length ? (
          <EmptyState
            title="No orders yet"
            description="New orders will appear here as they come in."
            className="border-0"
          />
        ) : (
          <ul className="divide-y">
            {orders.map((order) => {
              const cfg = orderStatusConfig(order.status);
              return (
                <li key={order.id}>
                  <Link
                    href={`/orders?id=${order.id}`}
                    className="hover:bg-muted/50 flex items-center gap-3 rounded-lg px-3 py-2.5 transition-colors"
                  >
                    <div className="min-w-0 flex-1">
                      <div className="flex items-center gap-2">
                        <span className="truncate font-medium">
                          #{order.orderNumber}
                        </span>
                        <Badge variant={cfg.variant}>{cfg.label}</Badge>
                      </div>
                      <p className="text-muted-foreground truncate text-sm">
                        {order.customerName || "Guest"} · {order.itemsSummary || "—"}
                      </p>
                    </div>
                    <div className="text-right">
                      <p className="font-medium tabular-nums">
                        {formatCurrency(order.grandTotal)}
                      </p>
                      <p className="text-muted-foreground text-xs">
                        {timeAgo(order.placedAt)}
                      </p>
                    </div>
                  </Link>
                </li>
              );
            })}
          </ul>
        )}
      </CardContent>
    </Card>
  );
}
