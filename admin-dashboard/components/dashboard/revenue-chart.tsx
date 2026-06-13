"use client"

import {
  Area,
  AreaChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
  CartesianGrid
} from "recharts"

const data = [
  { name: "Mon", total: 1200 },
  { name: "Tue", total: 2100 },
  { name: "Wed", total: 1800 },
  { name: "Thu", total: 2400 },
  { name: "Fri", total: 3200 },
  { name: "Sat", total: 4100 },
  { name: "Sun", total: 3800 },
]

export function RevenueChart({ data: propData }: { data?: any[] }) {
  const chartData = propData?.length ? propData : data
  return (
    <ResponsiveContainer width="100%" height="100%">
      <AreaChart data={chartData} margin={{ top: 10, right: 10, left: 0, bottom: 0 }}>
        <defs>
          <linearGradient id="colorTotal" x1="0" y1="0" x2="0" y2="1">
            <stop offset="5%" stopColor="hsl(185, 100%, 55%)" stopOpacity={0.3} />
            <stop offset="95%" stopColor="hsl(185, 100%, 55%)" stopOpacity={0} />
          </linearGradient>
        </defs>
        <CartesianGrid strokeDasharray="3 3" stroke="hsl(224, 12%, 16%)" vertical={false} />
        <XAxis
          dataKey="name"
          stroke="#888888"
          fontSize={12}
          tickLine={false}
          axisLine={false}
          dy={10}
        />
        <YAxis
          stroke="#888888"
          fontSize={12}
          tickLine={false}
          axisLine={false}
          tickFormatter={(value) => `৳${value}`}
          dx={-10}
        />
        <Tooltip 
          contentStyle={{ 
            backgroundColor: 'hsl(224, 18%, 9%)', 
            borderColor: 'hsl(224, 12%, 16%)',
            borderRadius: '8px',
            color: 'hsl(0, 0%, 95%)'
          }}
          itemStyle={{ color: 'hsl(185, 100%, 55%)' }}
        />
        <Area
          type="monotone"
          dataKey="total"
          stroke="hsl(185, 100%, 55%)"
          strokeWidth={3}
          fill="url(#colorTotal)"
          animationDuration={1500}
        />
      </AreaChart>
    </ResponsiveContainer>
  )
}
