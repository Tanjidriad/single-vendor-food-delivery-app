"use client"

import { useQuery } from "@tanstack/react-query"
import { Bike, ShieldAlert } from "lucide-react"

import { DataTable } from "@/components/tables/data-table"
import { columns } from "./columns"
import { fetchClient } from "@/lib/api/client"
import { Button } from "@/components/ui/button"
import { motion } from "framer-motion"

export default function RidersPage() {
  const { data, isLoading } = useQuery({
    queryKey: ['admin-riders'],
    queryFn: () => fetchClient<any>('/admin/riders?limit=50'),
  })

  // /admin/riders returns an array directly
  const riders = Array.isArray(data) ? data : []
  const pendingCount = riders.filter((r: any) => r.approvalStatus === 'PENDING').length || 0

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
            <Bike className="h-8 w-8 text-amber-500" />
            Riders
          </h2>
          <p className="text-slate-500 font-medium mt-1">
            Manage rider approvals, tracking, and delivery performance.
          </p>
        </div>
        {pendingCount > 0 && (
          <Button variant="outline" className="w-full sm:w-auto bg-white border-slate-200 text-slate-700 hover:bg-slate-50 font-bold rounded-full shadow-sm">
            <ShieldAlert className="mr-2 h-4 w-4" />
            {pendingCount} Pending Approvals
          </Button>
        )}
      </div>

      <div className="w-full bg-white rounded-3xl overflow-hidden shadow-[0_4px_25px_rgba(0,0,0,0.03)] border border-slate-50 p-1">
        {isLoading ? (
          <div className="h-[400px] w-full flex items-center justify-center rounded-md bg-transparent">
            <div className="flex flex-col items-center gap-4 text-muted-foreground">
              <div className="relative flex items-center justify-center">
                <div className="absolute inset-0 glow-amber opacity-50 blur-xl rounded-full" />
                <div className="h-10 w-10 animate-spin rounded-full border-4 border-amber-500/30 border-t-amber-500 z-10" />
              </div>
              <p className="font-medium animate-pulse text-amber-200">Loading riders...</p>
            </div>
          </div>
        ) : (
          <DataTable columns={columns} data={riders} />
        )}
      </div>
    </motion.div>
  )
}
