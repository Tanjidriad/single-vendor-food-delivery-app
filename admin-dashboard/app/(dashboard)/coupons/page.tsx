"use client"

import { useQuery } from "@tanstack/react-query"
import { Ticket, Plus } from "lucide-react"
import { fetchClient } from "@/lib/api/client"
import { Button } from "@/components/ui/button"
import { motion } from "framer-motion"

export default function CouponsPage() {
  const { data, isLoading } = useQuery({
    queryKey: ['admin-coupons'],
    queryFn: () => fetchClient<any>('/admin/restaurant/coupons'),
  })

  return (
    <motion.div 
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.4 }}
      className="space-y-6"
    >
      <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between bg-white p-6 rounded-3xl shadow-[0_4px_25px_rgba(0,0,0,0.03)] border border-slate-50">
        <div>
          <h2 className="text-3xl font-bold tracking-tight flex items-center gap-2">
            <Ticket className="h-8 w-8 text-emerald-500" />
            Coupons
          </h2>
          <p className="text-slate-500 font-medium mt-1">
            Create discount codes, set limits, and validate expiry dates.
          </p>
        </div>
        <Button className="bg-gradient-to-r from-red-400 to-rose-400 text-white rounded-full font-bold shadow-md shadow-red-500/20 hover:shadow-red-500/40 transition-all border-0 h-10 px-6">
          <Plus className="mr-2 h-4 w-4" />
          Create Coupon
        </Button>
      </div>

      <div className="w-full bg-white rounded-3xl overflow-hidden shadow-[0_4px_25px_rgba(0,0,0,0.03)] border border-slate-50 p-16 flex flex-col items-center justify-center min-h-[400px]">
        {isLoading ? (
          <div className="flex flex-col items-center gap-4 text-muted-foreground">
            <div className="relative flex items-center justify-center">
              <div className="absolute inset-0 glow-emerald opacity-50 blur-xl rounded-full" />
              <div className="h-10 w-10 animate-spin rounded-full border-4 border-emerald-500/30 border-t-emerald-500 z-10" />
            </div>
            <p className="font-medium animate-pulse text-emerald-200">Loading coupons...</p>
          </div>
        ) : (
          <div className="text-center">
            <Ticket className="h-12 w-12 text-muted-foreground/30 mx-auto mb-4" />
            <h3 className="text-lg font-medium">Active Coupons</h3>
            <p className="text-sm text-muted-foreground max-w-sm mt-2">
              Coupons table UI will be rendered here.
            </p>
          </div>
        )}
      </div>
    </motion.div>
  )
}
