"use client"

import { useQuery } from "@tanstack/react-query"
import { Users } from "lucide-react"

import { DataTable } from "@/components/tables/data-table"
import { columns } from "./columns"
import { fetchClient } from "@/lib/api/client"
import { motion } from "framer-motion"

export default function UsersPage() {
  const { data, isLoading } = useQuery({
    queryKey: ['admin-users'],
    queryFn: () => fetchClient<any>('/admin/users?limit=50'),
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
            <Users className="h-8 w-8 text-magenta-500" />
            Users
          </h2>
          <p className="text-slate-500 font-medium mt-1">
            Manage customers, staff, and rider accounts across the platform.
          </p>
        </div>
      </div>

      <div className="w-full bg-white rounded-3xl overflow-hidden shadow-[0_4px_25px_rgba(0,0,0,0.03)] border border-slate-50 p-1">
        {isLoading ? (
          <div className="h-[400px] w-full flex items-center justify-center rounded-md bg-transparent">
            <div className="flex flex-col items-center gap-4 text-muted-foreground">
              <div className="relative flex items-center justify-center">
                <div className="absolute inset-0 glow-magenta opacity-50 blur-xl rounded-full" />
                <div className="h-10 w-10 animate-spin rounded-full border-4 border-magenta-500/30 border-t-magenta-500 z-10" />
              </div>
              <p className="font-medium animate-pulse text-magenta-200">Loading users...</p>
            </div>
          </div>
        ) : (
          <DataTable columns={columns} data={data?.data || []} />
        )}
      </div>
    </motion.div>
  )
}
