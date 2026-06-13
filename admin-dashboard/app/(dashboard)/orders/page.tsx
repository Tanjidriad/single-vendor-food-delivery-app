"use client"

import { useQuery } from "@tanstack/react-query"
import { ShoppingBag, Filter } from "lucide-react"

import { DataTable } from "@/components/tables/data-table"
import { columns } from "./columns"
import { fetchClient } from "@/lib/api/client"
import { Button } from "@/components/ui/button"
import { motion } from "framer-motion"

export default function OrdersPage() {
  const { data, isLoading } = useQuery({
    queryKey: ['admin-orders'],
    queryFn: () => fetchClient<any>('/admin/super/orders?limit=100'),
  })

  return (
    <motion.div 
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.4 }}
      className="space-y-6"
    >
      <div className="w-full bg-white rounded-[24px] overflow-hidden shadow-[0_4px_20px_rgba(0,0,0,0.02)] border border-slate-100 p-6">
        <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between mb-6">
          <h2 className="text-[22px] font-bold tracking-tight text-slate-800">
            <span className="text-red-500">Live</span> Order Tracking
          </h2>
          <div className="flex items-center gap-2">
            <select className="border border-slate-200 bg-white text-slate-600 text-sm font-medium py-2 px-4 rounded-lg shadow-sm outline-none focus:border-slate-300 cursor-pointer appearance-none pr-8 relative">
              <option>Today</option>
              <option>Yesterday</option>
              <option>This Week</option>
            </select>
            {/* Adding custom dropdown arrow using CSS is cleaner, but keeping native for simplicity unless asked */}
          </div>
        </div>
        {isLoading ? (
          <div className="h-[400px] w-full flex items-center justify-center rounded-md bg-transparent">
            <div className="flex flex-col items-center gap-4 text-muted-foreground">
              <div className="relative flex items-center justify-center">
                <div className="absolute inset-0 glow-violet opacity-50 blur-xl rounded-full" />
                <div className="h-10 w-10 animate-spin rounded-full border-4 border-violet-500/30 border-t-violet-500 z-10" />
              </div>
              <p className="font-medium animate-pulse text-violet-200">Loading live orders...</p>
            </div>
          </div>
        ) : (
          <DataTable columns={columns} data={data?.data || []} />
        )}
      </div>
    </motion.div>
  )
}
