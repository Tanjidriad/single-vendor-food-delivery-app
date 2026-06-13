"use client";

import { Printer, Bike, ShoppingBag, Clock } from "lucide-react";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";

export type OrderStatus = "new" | "in_progress" | "ready";

export interface OrderItem {
  name: string;
  quantity: number;
  modifiers?: string[];
}

export interface Order {
  id: string;
  customerName: string;
  items: OrderItem[];
  notes?: string[];
  placedMinutesAgo: number;
  isOverdue?: boolean;
  deliveryType: "rider" | "pickup";
  platform: string;
  status: OrderStatus;
}

interface OrderCardProps {
  order: Order;
  onAction: (orderId: string) => void;
  onPrint?: (orderId: string) => void;
}

export function OrderCard({ order, onAction, onPrint }: OrderCardProps) {
  const getActionButton = () => {
    switch (order.status) {
      case "new":
        return {
          label: "Accept Order",
          className: "bg-kds-success hover:bg-kds-success/90 text-black",
        };
      case "in_progress":
        return {
          label: "Mark Ready",
          className: "bg-kds-info hover:bg-kds-info/90 text-white",
        };
      case "ready":
        return {
          label: "Complete Handoff",
          className: "bg-kds-warning hover:bg-kds-warning/90 text-black",
        };
    }
  };

  const actionBtn = getActionButton();

  return (
    <div className="bg-card rounded-lg border border-border overflow-hidden flex flex-col">
      {/* Card Header */}
      <div className="px-3 md:px-4 py-2.5 md:py-3 border-b border-border flex items-center justify-between">
        <div className="flex items-center gap-2 md:gap-3">
          <span className="text-base md:text-lg font-bold text-foreground">#{order.id}</span>
          <span className="text-xs md:text-sm text-muted-foreground">{order.customerName}</span>
        </div>
        <div className="flex items-center gap-2">
          {order.deliveryType === "rider" ? (
            <Bike className="w-4 h-4 md:w-5 md:h-5 text-kds-info" />
          ) : (
            <ShoppingBag className="w-4 h-4 md:w-5 md:h-5 text-kds-warning" />
          )}
        </div>
      </div>

      {/* Timer Badge */}
      <div className="px-3 md:px-4 pt-2.5 md:pt-3">
        <div
          className={cn(
            "inline-flex items-center gap-1 md:gap-1.5 px-2 md:px-3 py-1 md:py-1.5 rounded-full text-xs md:text-sm font-semibold",
            order.isOverdue
              ? "bg-kds-urgent/20 text-kds-urgent"
              : "bg-secondary text-muted-foreground"
          )}
        >
          <Clock className="w-3.5 h-3.5 md:w-4 md:h-4" />
          <span>{order.placedMinutesAgo} min ago</span>
        </div>
      </div>

      {/* Order Items */}
      <div className="px-3 md:px-4 py-2.5 md:py-3 flex-1">
        <ul className="space-y-1.5 md:space-y-2">
          {order.items.map((item, idx) => (
            <li key={idx} className="flex items-start gap-2">
              <span className="text-muted-foreground font-medium min-w-[1.25rem] md:min-w-[1.5rem] text-sm md:text-base">
                {item.quantity}x
              </span>
              <div className="flex-1">
                <span className="text-foreground font-medium text-sm md:text-base">{item.name}</span>
                {item.modifiers && item.modifiers.length > 0 && (
                  <div className="flex flex-wrap gap-1 mt-1">
                    {item.modifiers.map((mod, modIdx) => (
                      <span
                        key={modIdx}
                        className="text-[10px] md:text-xs px-1.5 md:px-2 py-0.5 rounded bg-kds-modifier/20 text-kds-modifier font-medium"
                      >
                        {mod}
                      </span>
                    ))}
                  </div>
                )}
              </div>
            </li>
          ))}
        </ul>
      </div>

      {/* Notes */}
      {order.notes && order.notes.length > 0 && (
        <div className="px-3 md:px-4 pb-2.5 md:pb-3">
          <div className="bg-kds-modifier/15 border border-kds-modifier/30 rounded-md p-2 md:p-2.5">
            {order.notes.map((note, idx) => (
              <p key={idx} className="text-xs md:text-sm font-semibold text-kds-modifier">
                {note}
              </p>
            ))}
          </div>
        </div>
      )}

      {/* Card Footer */}
      <div className="px-3 md:px-4 pb-3 md:pb-4 pt-1.5 md:pt-2 flex items-center gap-2">
        <Button
          variant="outline"
          size="icon"
          className="shrink-0 border-border hover:bg-secondary h-10 w-10 md:h-10 md:w-10"
          onClick={() => onPrint?.(order.id)}
        >
          <Printer className="w-4 h-4" />
        </Button>
        <Button
          className={cn("flex-1 h-11 md:h-12 text-sm md:text-base font-bold", actionBtn.className)}
          onClick={() => onAction(order.id)}
        >
          {actionBtn.label}
        </Button>
      </div>
    </div>
  );
}
