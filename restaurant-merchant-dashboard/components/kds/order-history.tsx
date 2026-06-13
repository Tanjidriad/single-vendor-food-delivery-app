"use client";

import { useState } from "react";
import { 
  Search, 
  Calendar, 
  Filter, 
  Bike, 
  ShoppingBag, 
  CheckCircle2,
  XCircle,
  Clock,
  ChevronDown,
  ChevronRight
} from "lucide-react";
import { cn } from "@/lib/utils";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";

export interface CompletedOrder {
  id: string;
  customerName: string;
  items: { name: string; quantity: number }[];
  total: number;
  platform: string;
  deliveryType: "rider" | "pickup";
  completedAt: string;
  prepTime: number; // minutes
  status: "completed" | "cancelled" | "refunded";
}

interface OrderHistoryProps {
  orders: CompletedOrder[];
}

export function OrderHistory({ orders }: OrderHistoryProps) {
  const [searchQuery, setSearchQuery] = useState("");
  const [expandedOrder, setExpandedOrder] = useState<string | null>(null);
  const [filterStatus, setFilterStatus] = useState<string>("all");

  const filteredOrders = orders.filter((order) => {
    const matchesSearch =
      order.id.toLowerCase().includes(searchQuery.toLowerCase()) ||
      order.customerName.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesFilter = filterStatus === "all" || order.status === filterStatus;
    return matchesSearch && matchesFilter;
  });

  const todayOrders = filteredOrders.filter((o) => o.completedAt.includes("Today"));
  const yesterdayOrders = filteredOrders.filter((o) => o.completedAt.includes("Yesterday"));

  const getStatusIcon = (status: string) => {
    switch (status) {
      case "completed":
        return <CheckCircle2 className="w-4 h-4 text-kds-success" />;
      case "cancelled":
        return <XCircle className="w-4 h-4 text-kds-urgent" />;
      case "refunded":
        return <XCircle className="w-4 h-4 text-kds-warning" />;
      default:
        return null;
    }
  };

  const OrderCard = ({ order }: { order: CompletedOrder }) => {
    const isExpanded = expandedOrder === order.id;

    return (
      <div
        className={cn(
          "bg-card border border-border rounded-lg overflow-hidden transition-all",
          isExpanded && "ring-1 ring-kds-info/50"
        )}
      >
        <button
          onClick={() => setExpandedOrder(isExpanded ? null : order.id)}
          className="w-full p-3 md:p-4 flex items-center gap-3 text-left"
        >
          {/* Status Icon */}
          <div className="flex-shrink-0">{getStatusIcon(order.status)}</div>

          {/* Order Info */}
          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-2">
              <span className="font-mono font-bold text-foreground">#{order.id}</span>
              <span className="text-muted-foreground">-</span>
              <span className="text-foreground truncate">{order.customerName}</span>
            </div>
            <div className="flex items-center gap-2 mt-1 text-xs text-muted-foreground">
              {order.deliveryType === "rider" ? (
                <Bike className="w-3 h-3" />
              ) : (
                <ShoppingBag className="w-3 h-3" />
              )}
              <span>{order.platform}</span>
              <span>-</span>
              <span>{order.completedAt}</span>
            </div>
          </div>

          {/* Prep Time & Total */}
          <div className="text-right flex-shrink-0">
            <div className="font-semibold text-foreground">${order.total.toFixed(2)}</div>
            <div className="flex items-center gap-1 text-xs text-muted-foreground mt-1">
              <Clock className="w-3 h-3" />
              <span>{order.prepTime}m</span>
            </div>
          </div>

          {/* Expand Icon */}
          <ChevronRight
            className={cn(
              "w-5 h-5 text-muted-foreground transition-transform flex-shrink-0",
              isExpanded && "rotate-90"
            )}
          />
        </button>

        {/* Expanded Details */}
        {isExpanded && (
          <div className="px-3 md:px-4 pb-3 md:pb-4 border-t border-border">
            <div className="pt-3 space-y-2">
              <h4 className="text-xs font-semibold text-muted-foreground uppercase tracking-wider">
                Items
              </h4>
              {order.items.map((item, idx) => (
                <div key={idx} className="flex justify-between text-sm">
                  <span className="text-foreground">
                    {item.quantity}x {item.name}
                  </span>
                </div>
              ))}
            </div>
            <div className="mt-4 flex gap-2">
              <Button variant="outline" size="sm" className="flex-1">
                View Receipt
              </Button>
              <Button variant="outline" size="sm" className="flex-1">
                Reprint
              </Button>
            </div>
          </div>
        )}
      </div>
    );
  };

  const OrderGroup = ({ title, orders }: { title: string; orders: CompletedOrder[] }) => {
    if (orders.length === 0) return null;

    return (
      <div className="space-y-3">
        <h3 className="text-sm font-semibold text-muted-foreground uppercase tracking-wider px-1">
          {title} ({orders.length})
        </h3>
        <div className="space-y-2">
          {orders.map((order) => (
            <OrderCard key={order.id} order={order} />
          ))}
        </div>
      </div>
    );
  };

  return (
    <div className="flex-1 flex flex-col min-h-0 p-3 md:p-6">
      {/* Header */}
      <div className="mb-4 md:mb-6">
        <h1 className="text-xl md:text-2xl font-bold text-foreground">Order History</h1>
        <p className="text-sm text-muted-foreground mt-1">
          View and search past orders
        </p>
      </div>

      {/* Search & Filters */}
      <div className="flex flex-col sm:flex-row gap-3 mb-4 md:mb-6">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
          <Input
            placeholder="Search by order # or customer..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="pl-10 bg-secondary border-border"
          />
        </div>
        <div className="flex gap-2">
          <Button variant="outline" size="icon" className="flex-shrink-0">
            <Calendar className="w-4 h-4" />
          </Button>
          <select
            value={filterStatus}
            onChange={(e) => setFilterStatus(e.target.value)}
            className="h-9 px-3 rounded-md border border-border bg-secondary text-sm text-foreground"
          >
            <option value="all">All Status</option>
            <option value="completed">Completed</option>
            <option value="cancelled">Cancelled</option>
            <option value="refunded">Refunded</option>
          </select>
        </div>
      </div>

      {/* Stats Bar */}
      <div className="grid grid-cols-3 gap-2 md:gap-4 mb-4 md:mb-6">
        <div className="bg-card border border-border rounded-lg p-3 md:p-4">
          <div className="text-xl md:text-2xl font-bold text-foreground">
            {orders.filter((o) => o.status === "completed").length}
          </div>
          <div className="text-xs text-muted-foreground mt-1">Completed Today</div>
        </div>
        <div className="bg-card border border-border rounded-lg p-3 md:p-4">
          <div className="text-xl md:text-2xl font-bold text-kds-success">
            ${orders.filter((o) => o.status === "completed").reduce((sum, o) => sum + o.total, 0).toFixed(0)}
          </div>
          <div className="text-xs text-muted-foreground mt-1">Revenue Today</div>
        </div>
        <div className="bg-card border border-border rounded-lg p-3 md:p-4">
          <div className="text-xl md:text-2xl font-bold text-foreground">
            {Math.round(
              orders.filter((o) => o.status === "completed").reduce((sum, o) => sum + o.prepTime, 0) /
                Math.max(orders.filter((o) => o.status === "completed").length, 1)
            )}m
          </div>
          <div className="text-xs text-muted-foreground mt-1">Avg Prep Time</div>
        </div>
      </div>

      {/* Order List */}
      <div className="flex-1 overflow-y-auto space-y-6 pb-20 md:pb-0">
        <OrderGroup title="Today" orders={todayOrders} />
        <OrderGroup title="Yesterday" orders={yesterdayOrders} />

        {filteredOrders.length === 0 && (
          <div className="text-center py-12">
            <div className="text-muted-foreground">No orders found</div>
          </div>
        )}
      </div>
    </div>
  );
}
