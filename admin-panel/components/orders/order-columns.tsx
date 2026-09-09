"use client";

import type { ColumnDef } from "@tanstack/react-table";

import { Badge } from "@/components/ui/badge";
import { orderStatusConfig } from "@/lib/order-status";
import { formatCurrency, formatDateTime } from "@/lib/utils";
import type { OrderListItem } from "@/types";

export const orderColumns: ColumnDef<OrderListItem>[] = [
  {
    accessorKey: "orderNumber",
    header: "Order",
    cell: ({ row }) => {
      const o = row.original;
      return (
        <div className="min-w-0">
          <p className="font-medium">#{o.orderNumber}</p>
          <p className="text-muted-foreground max-w-[220px] truncate text-xs">
            {o.itemsSummary || "—"}
          </p>
        </div>
      );
    },
  },
  {
    accessorKey: "customerName",
    header: "Customer",
    cell: ({ row }) => {
      const o = row.original;
      return (
        <div className="min-w-0">
          <p className="truncate">{o.customerName || "Guest"}</p>
          <p className="text-muted-foreground text-xs">{o.customerPhone || "—"}</p>
        </div>
      );
    },
  },
  {
    accessorKey: "status",
    header: "Status",
    cell: ({ row }) => {
      const cfg = orderStatusConfig(row.original.status);
      return <Badge variant={cfg.variant}>{cfg.label}</Badge>;
    },
  },
  {
    accessorKey: "paymentMethod",
    header: "Payment",
    cell: ({ row }) => (
      <div className="text-sm">
        <span className="font-medium">{row.original.paymentMethod}</span>
        <Badge
          variant={
            row.original.paymentStatus === "PAID" ? "success" : "muted"
          }
          className="ml-2"
        >
          {row.original.paymentStatus}
        </Badge>
      </div>
    ),
  },
  {
    accessorKey: "riderName",
    header: "Rider",
    cell: ({ row }) => (
      <span className="text-sm">{row.original.riderName || "—"}</span>
    ),
  },
  {
    accessorKey: "grandTotal",
    header: "Total",
    cell: ({ row }) => (
      <span className="font-medium tabular-nums">
        {formatCurrency(row.original.grandTotal)}
      </span>
    ),
  },
  {
    accessorKey: "placedAt",
    header: "Placed",
    cell: ({ row }) => (
      <span className="text-muted-foreground text-sm">
        {formatDateTime(row.original.placedAt)}
      </span>
    ),
  },
];
