"use client";

import { TrendingUp } from "lucide-react";

import {
  Card,
  CardHeader,
  CardTitle,
  CardContent,
} from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { EmptyState } from "@/components/common/empty-state";
import { formatCurrency } from "@/lib/utils";
import type { PopularItem } from "@/types";

export function TopItems({
  items,
  loading,
}: {
  items?: PopularItem[];
  loading?: boolean;
}) {
  return (
    <Card>
      <CardHeader className="border-b">
        <CardTitle>Top selling items</CardTitle>
      </CardHeader>
      <CardContent className="px-2">
        {loading ? (
          <div className="space-y-1 p-2">
            {Array.from({ length: 5 }).map((_, i) => (
              <Skeleton key={i} className="h-12 w-full" />
            ))}
          </div>
        ) : !items?.length ? (
          <EmptyState
            icon={TrendingUp}
            title="No sales data yet"
            description="Best-selling items will show here once orders are delivered."
            className="border-0"
          />
        ) : (
          <ul className="space-y-0.5">
            {items.map((item, i) => (
              <li
                key={item.id}
                className="flex items-center gap-3 rounded-lg px-3 py-2"
              >
                <span className="bg-muted text-muted-foreground flex size-6 shrink-0 items-center justify-center rounded-md text-xs font-semibold">
                  {i + 1}
                </span>
                {/* eslint-disable-next-line @next/next/no-img-element */}
                {item.imageUrl ? (
                  <img
                    src={item.imageUrl}
                    alt=""
                    className="size-9 shrink-0 rounded-md object-cover"
                  />
                ) : (
                  <div className="bg-muted size-9 shrink-0 rounded-md" />
                )}
                <div className="min-w-0 flex-1">
                  <p className="truncate text-sm font-medium">{item.name}</p>
                  <p className="text-muted-foreground truncate text-xs">
                    {item.category?.name ?? "Menu item"}
                  </p>
                </div>
                <div className="text-right">
                  <p className="text-sm font-medium tabular-nums">
                    {item.totalSales} sold
                  </p>
                  <p className="text-muted-foreground text-xs tabular-nums">
                    {formatCurrency(item.price)}
                  </p>
                </div>
              </li>
            ))}
          </ul>
        )}
      </CardContent>
    </Card>
  );
}
