"use client";

import { OrderCard, Order } from "./order-card";
import { cn } from "@/lib/utils";

interface KanbanColumnProps {
  title: string;
  orders: Order[];
  accentColor: "success" | "warning" | "info";
  onOrderAction: (orderId: string) => void;
  onPrintOrder?: (orderId: string) => void;
  isMobileActive?: boolean;
}

const accentColors = {
  success: "border-t-kds-success",
  warning: "border-t-kds-warning",
  info: "border-t-kds-info",
};

const badgeColors = {
  success: "bg-kds-success/20 text-kds-success",
  warning: "bg-kds-warning/20 text-kds-warning",
  info: "bg-kds-info/20 text-kds-info",
};

export function KanbanColumn({
  title,
  orders,
  accentColor,
  onOrderAction,
  onPrintOrder,
  isMobileActive = true,
}: KanbanColumnProps) {
  return (
    <div
      className={cn(
        "bg-muted/30 rounded-xl border-t-4 flex flex-col min-h-0",
        "flex-1 hidden md:flex", // Desktop: show all columns
        isMobileActive && "!flex", // Mobile: only show active
        accentColors[accentColor]
      )}
    >
      {/* Column Header */}
      <div className="px-4 py-3 md:py-4 flex items-center justify-between border-b border-border">
        <h2 className="text-base md:text-lg font-bold text-foreground">{title}</h2>
        <span
          className={cn(
            "px-2.5 md:px-3 py-0.5 md:py-1 rounded-full text-sm font-bold",
            badgeColors[accentColor]
          )}
        >
          {orders.length}
        </span>
      </div>

      {/* Column Content */}
      <div className="flex-1 overflow-y-auto p-3 md:p-4 space-y-3 md:space-y-4">
        {orders.map((order) => (
          <OrderCard
            key={order.id}
            order={order}
            onAction={onOrderAction}
            onPrint={onPrintOrder}
          />
        ))}
        {orders.length === 0 && (
          <div className="h-32 flex items-center justify-center text-muted-foreground text-sm">
            No orders
          </div>
        )}
      </div>
    </div>
  );
}

// Mobile Tab Selector Component
interface MobileTabSelectorProps {
  activeTab: number;
  onTabChange: (tab: number) => void;
  counts: { new: number; inProgress: number; ready: number };
}

export function MobileTabSelector({ activeTab, onTabChange, counts }: MobileTabSelectorProps) {
  const tabs = [
    { label: "New", count: counts.new, color: "success" as const },
    { label: "In Progress", count: counts.inProgress, color: "warning" as const },
    { label: "Ready", count: counts.ready, color: "info" as const },
  ];

  return (
    <div className="md:hidden flex gap-2 px-4 py-3 bg-card border-b border-border overflow-x-auto">
      {tabs.map((tab, idx) => (
        <button
          key={idx}
          onClick={() => onTabChange(idx)}
          className={cn(
            "flex-1 min-w-[5.5rem] px-3 py-2.5 rounded-lg font-semibold text-sm transition-all flex items-center justify-center gap-2",
            activeTab === idx
              ? cn(
                  "text-black",
                  tab.color === "success" && "bg-kds-success",
                  tab.color === "warning" && "bg-kds-warning",
                  tab.color === "info" && "bg-kds-info text-white"
                )
              : "bg-secondary text-muted-foreground"
          )}
        >
          <span>{tab.label}</span>
          <span
            className={cn(
              "min-w-[1.25rem] h-5 px-1 rounded-full text-xs font-bold flex items-center justify-center",
              activeTab === idx
                ? "bg-black/20 text-inherit"
                : badgeColors[tab.color]
            )}
          >
            {tab.count}
          </span>
        </button>
      ))}
    </div>
  );
}
