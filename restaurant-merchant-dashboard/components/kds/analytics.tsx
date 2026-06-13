"use client";

import { useState } from "react";
import {
  TrendingUp,
  TrendingDown,
  Clock,
  DollarSign,
  ShoppingBag,
  Bike,
  Star,
  Users,
  ChevronDown,
} from "lucide-react";
import { cn } from "@/lib/utils";

interface StatCardProps {
  title: string;
  value: string;
  change: number;
  changeLabel: string;
  icon: React.ReactNode;
}

function StatCard({ title, value, change, changeLabel, icon }: StatCardProps) {
  const isPositive = change >= 0;

  return (
    <div className="bg-card border border-border rounded-xl p-4 md:p-5">
      <div className="flex items-start justify-between mb-3">
        <div className="w-10 h-10 rounded-lg bg-secondary flex items-center justify-center">
          {icon}
        </div>
        <div
          className={cn(
            "flex items-center gap-1 text-xs font-medium px-2 py-1 rounded-full",
            isPositive ? "bg-kds-success/20 text-kds-success" : "bg-kds-urgent/20 text-kds-urgent"
          )}
        >
          {isPositive ? <TrendingUp className="w-3 h-3" /> : <TrendingDown className="w-3 h-3" />}
          {Math.abs(change)}%
        </div>
      </div>
      <div className="text-2xl md:text-3xl font-bold text-foreground">{value}</div>
      <div className="text-xs text-muted-foreground mt-1">{changeLabel}</div>
      <div className="text-sm text-muted-foreground mt-2">{title}</div>
    </div>
  );
}

interface BarChartProps {
  data: { label: string; value: number; maxValue: number }[];
  title: string;
  color: string;
}

function SimpleBarChart({ data, title, color }: BarChartProps) {
  return (
    <div className="bg-card border border-border rounded-xl p-4 md:p-5">
      <h3 className="text-sm font-semibold text-foreground mb-4">{title}</h3>
      <div className="space-y-3">
        {data.map((item, idx) => (
          <div key={idx} className="space-y-1">
            <div className="flex justify-between text-xs">
              <span className="text-muted-foreground">{item.label}</span>
              <span className="text-foreground font-medium">{item.value}</span>
            </div>
            <div className="h-2 bg-secondary rounded-full overflow-hidden">
              <div
                className={cn("h-full rounded-full transition-all", color)}
                style={{ width: `${(item.value / item.maxValue) * 100}%` }}
              />
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

interface TopItemProps {
  rank: number;
  name: string;
  orders: number;
  revenue: number;
}

function TopItem({ rank, name, orders, revenue }: TopItemProps) {
  return (
    <div className="flex items-center gap-3 py-2.5 border-b border-border last:border-0">
      <div
        className={cn(
          "w-6 h-6 rounded-full flex items-center justify-center text-xs font-bold",
          rank === 1
            ? "bg-kds-warning text-primary-foreground"
            : rank === 2
            ? "bg-muted-foreground/30 text-foreground"
            : "bg-secondary text-muted-foreground"
        )}
      >
        {rank}
      </div>
      <div className="flex-1 min-w-0">
        <div className="font-medium text-foreground text-sm truncate">{name}</div>
        <div className="text-xs text-muted-foreground">{orders} orders</div>
      </div>
      <div className="text-sm font-semibold text-kds-success">${revenue}</div>
    </div>
  );
}

export function Analytics() {
  const [timeRange, setTimeRange] = useState("today");

  const hourlyData = [
    { label: "11 AM", value: 12, maxValue: 25 },
    { label: "12 PM", value: 25, maxValue: 25 },
    { label: "1 PM", value: 22, maxValue: 25 },
    { label: "2 PM", value: 15, maxValue: 25 },
    { label: "5 PM", value: 18, maxValue: 25 },
    { label: "6 PM", value: 24, maxValue: 25 },
    { label: "7 PM", value: 20, maxValue: 25 },
  ];

  const platformData = [
    { label: "UberEats", value: 45, maxValue: 100 },
    { label: "DoorDash", value: 32, maxValue: 100 },
    { label: "Direct", value: 23, maxValue: 100 },
  ];

  const topItems = [
    { rank: 1, name: "Classic Cheeseburger", orders: 87, revenue: 1131 },
    { rank: 2, name: "Double Bacon Burger", orders: 64, revenue: 960 },
    { rank: 3, name: "Fish Tacos", orders: 52, revenue: 728 },
    { rank: 4, name: "Spicy Chicken Sandwich", orders: 48, revenue: 624 },
    { rank: 5, name: "BBQ Pulled Pork", orders: 41, revenue: 533 },
  ];

  return (
    <div className="flex-1 flex flex-col min-h-0 p-3 md:p-6 overflow-y-auto pb-20 md:pb-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 mb-4 md:mb-6">
        <div>
          <h1 className="text-xl md:text-2xl font-bold text-foreground">Analytics</h1>
          <p className="text-sm text-muted-foreground mt-1">Track your kitchen performance</p>
        </div>
        <select
          value={timeRange}
          onChange={(e) => setTimeRange(e.target.value)}
          className="h-9 px-3 rounded-md border border-border bg-secondary text-sm text-foreground w-full sm:w-auto"
        >
          <option value="today">Today</option>
          <option value="week">This Week</option>
          <option value="month">This Month</option>
        </select>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-3 md:gap-4 mb-4 md:mb-6">
        <StatCard
          title="Total Orders"
          value="127"
          change={12}
          changeLabel="vs yesterday"
          icon={<ShoppingBag className="w-5 h-5 text-kds-info" />}
        />
        <StatCard
          title="Revenue"
          value="$2,847"
          change={8}
          changeLabel="vs yesterday"
          icon={<DollarSign className="w-5 h-5 text-kds-success" />}
        />
        <StatCard
          title="Avg Prep Time"
          value="14m"
          change={-5}
          changeLabel="faster today"
          icon={<Clock className="w-5 h-5 text-kds-warning" />}
        />
        <StatCard
          title="Delivery Orders"
          value="89%"
          change={3}
          changeLabel="vs pickup"
          icon={<Bike className="w-5 h-5 text-kds-info" />}
        />
      </div>

      {/* Charts Row */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-3 md:gap-4 mb-4 md:mb-6">
        <SimpleBarChart data={hourlyData} title="Orders by Hour" color="bg-kds-info" />
        <SimpleBarChart data={platformData} title="Orders by Platform" color="bg-kds-success" />
      </div>

      {/* Top Items & Metrics */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-3 md:gap-4">
        {/* Top Selling Items */}
        <div className="bg-card border border-border rounded-xl p-4 md:p-5">
          <h3 className="text-sm font-semibold text-foreground mb-4">Top Selling Items</h3>
          <div className="space-y-1">
            {topItems.map((item) => (
              <TopItem key={item.rank} {...item} />
            ))}
          </div>
        </div>

        {/* Performance Metrics */}
        <div className="bg-card border border-border rounded-xl p-4 md:p-5">
          <h3 className="text-sm font-semibold text-foreground mb-4">Performance Metrics</h3>
          <div className="space-y-4">
            <div className="flex items-center justify-between py-2 border-b border-border">
              <div className="flex items-center gap-3">
                <div className="w-8 h-8 rounded-lg bg-kds-success/20 flex items-center justify-center">
                  <Star className="w-4 h-4 text-kds-success" />
                </div>
                <div>
                  <div className="font-medium text-foreground text-sm">Order Accuracy</div>
                  <div className="text-xs text-muted-foreground">Correct orders</div>
                </div>
              </div>
              <div className="text-lg font-bold text-kds-success">98.2%</div>
            </div>
            <div className="flex items-center justify-between py-2 border-b border-border">
              <div className="flex items-center gap-3">
                <div className="w-8 h-8 rounded-lg bg-kds-warning/20 flex items-center justify-center">
                  <Clock className="w-4 h-4 text-kds-warning" />
                </div>
                <div>
                  <div className="font-medium text-foreground text-sm">On-Time Rate</div>
                  <div className="text-xs text-muted-foreground">Within target</div>
                </div>
              </div>
              <div className="text-lg font-bold text-kds-warning">94.5%</div>
            </div>
            <div className="flex items-center justify-between py-2 border-b border-border">
              <div className="flex items-center gap-3">
                <div className="w-8 h-8 rounded-lg bg-kds-urgent/20 flex items-center justify-center">
                  <Users className="w-4 h-4 text-kds-urgent" />
                </div>
                <div>
                  <div className="font-medium text-foreground text-sm">Cancelled Orders</div>
                  <div className="text-xs text-muted-foreground">Today</div>
                </div>
              </div>
              <div className="text-lg font-bold text-kds-urgent">3</div>
            </div>
            <div className="flex items-center justify-between py-2">
              <div className="flex items-center gap-3">
                <div className="w-8 h-8 rounded-lg bg-kds-info/20 flex items-center justify-center">
                  <TrendingUp className="w-4 h-4 text-kds-info" />
                </div>
                <div>
                  <div className="font-medium text-foreground text-sm">Peak Hour</div>
                  <div className="text-xs text-muted-foreground">Busiest time</div>
                </div>
              </div>
              <div className="text-lg font-bold text-foreground">12 PM</div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
