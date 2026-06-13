"use client"

import { Landmark, ArrowUpRight, FileDown, TrendingUp, Utensils, Bike, Wallet, Search } from "lucide-react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { formatCurrency } from "@/lib/utils"
import { motion } from "framer-motion"
import { useQuery } from "@tanstack/react-query"
import { fetchClient } from "@/lib/api/client"

export default function FinancialsPage() {
  const { data: stats } = useQuery({
    queryKey: ['admin-stats'],
    queryFn: () => fetchClient<any>('/admin/super/stats'),
  })

  return (
    <motion.div 
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.4 }}
      className="space-y-6"
    >
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between bg-white p-6 rounded-3xl shadow-[0_4px_25px_rgba(0,0,0,0.03)] border border-slate-50">
        <div>
          <h2 className="text-3xl font-bold tracking-tight flex items-center gap-2">
            <Landmark className="h-8 w-8 text-cyan-500" />
            Financials
          </h2>
          <p className="text-slate-500 font-medium mt-1">
            Track gross sales, net revenue, and rider ledger settlements.
          </p>
        </div>
        <div className="flex items-center gap-3">
          <select className="border border-slate-200 bg-white text-slate-600 text-sm font-medium py-2.5 px-4 rounded-xl shadow-sm outline-none focus:border-cyan-500 cursor-pointer appearance-none relative">
            <option>Today</option>
            <option>Yesterday</option>
            <option>This Week</option>
            <option>This Month</option>
          </select>
          <Button variant="outline" className="bg-white border-slate-200 text-slate-700 hover:bg-slate-50 font-bold rounded-xl shadow-sm h-10 px-4">
            <FileDown className="mr-2 h-4 w-4" />
            Export
          </Button>
        </div>
      </div>

      <div className="grid gap-4 md:grid-cols-4">
        {/* Total GMV */}
        <Card className="bg-white relative overflow-hidden border border-slate-100 shadow-sm hover:shadow-md hover:border-slate-200 transition-all">
          <div className="absolute inset-0 bg-gradient-to-br from-cyan-500/5 to-transparent pointer-events-none" />
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium text-slate-500">Gross Sales (GMV)</CardTitle>
            <div className="p-2 rounded-lg bg-cyan-500/10">
              <TrendingUp className="h-4 w-4 text-cyan-500" />
            </div>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-slate-800">{formatCurrency(stats?.totalGmv || 0)}</div>
            <p className="text-xs text-slate-500 font-medium mt-1 flex items-center text-emerald-600">
              <ArrowUpRight className="h-3 w-3 mr-1" />
              Total transaction volume
            </p>
          </CardContent>
        </Card>
        
        {/* Net Food Revenue */}
        <Card className="bg-white relative overflow-hidden border border-slate-100 shadow-sm hover:shadow-md hover:border-slate-200 transition-all">
          <div className="absolute inset-0 bg-gradient-to-br from-emerald-500/5 to-transparent pointer-events-none" />
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium text-slate-500">Net Food Revenue</CardTitle>
            <div className="p-2 rounded-lg bg-emerald-500/10">
              <Utensils className="h-4 w-4 text-emerald-500" />
            </div>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-slate-800">{formatCurrency(stats?.foodRevenue || 0)}</div>
            <p className="text-xs text-slate-500 mt-1">Excludes delivery fees & refunds</p>
          </CardContent>
        </Card>

        {/* Delivery Revenue */}
        <Card className="bg-white relative overflow-hidden border border-slate-100 shadow-sm hover:shadow-md hover:border-slate-200 transition-all">
          <div className="absolute inset-0 bg-gradient-to-br from-orange-500/5 to-transparent pointer-events-none" />
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium text-slate-500">Delivery Revenue</CardTitle>
            <div className="p-2 rounded-lg bg-orange-500/10">
              <Bike className="h-4 w-4 text-orange-500" />
            </div>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-slate-800">{formatCurrency(stats?.deliveryRevenue || 0)}</div>
            <p className="text-xs text-slate-500 mt-1">Collected from customers</p>
          </CardContent>
        </Card>

        {/* Rider Pending Pay */}
        <Card className="bg-white relative overflow-hidden border border-slate-100 shadow-sm hover:shadow-md hover:border-slate-200 transition-all">
          <div className="absolute inset-0 bg-gradient-to-br from-red-500/5 to-transparent pointer-events-none" />
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium text-slate-500">Rider Liability</CardTitle>
            <div className="p-2 rounded-lg bg-red-500/10">
              <Wallet className="h-4 w-4 text-red-500" />
            </div>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-slate-800">{formatCurrency(stats?.totalRiderLiability || 0)}</div>
            <p className="text-xs text-slate-500 mt-1">Pending unpaid ledger balance</p>
          </CardContent>
        </Card>
      </div>

      <div className="grid gap-6 md:grid-cols-2">
        {/* COD Settlements Table Placeholder */}
        <Card className="bg-white border border-slate-100 shadow-sm rounded-3xl overflow-hidden">
          <div className="p-6 border-b border-slate-100 flex items-center justify-between bg-slate-50/50">
            <div>
              <h3 className="font-bold text-lg text-slate-800">Pending COD Settlements</h3>
              <p className="text-sm text-slate-500">Cash collected by riders needing deposit.</p>
            </div>
            <Button variant="outline" size="sm" className="bg-white rounded-full">View All</Button>
          </div>
          <div className="p-8 text-center flex flex-col items-center justify-center bg-white min-h-[300px]">
            <div className="h-16 w-16 bg-slate-50 rounded-full flex items-center justify-center mb-4">
              <Search className="h-8 w-8 text-slate-300" />
            </div>
            <h4 className="font-bold text-slate-700">No pending cash deposits</h4>
            <p className="text-sm text-slate-500 mt-1">All COD orders have been settled successfully.</p>
          </div>
        </Card>

        {/* Rider Ledger Table Placeholder */}
        <Card className="bg-white border border-slate-100 shadow-sm rounded-3xl overflow-hidden">
          <div className="p-6 border-b border-slate-100 flex items-center justify-between bg-slate-50/50">
            <div>
              <h3 className="font-bold text-lg text-slate-800">Rider Payout Ledger</h3>
              <p className="text-sm text-slate-500">Manage fleet earnings and execute payouts.</p>
            </div>
            <Button variant="outline" size="sm" className="bg-white rounded-full">View All</Button>
          </div>
          <div className="p-8 text-center flex flex-col items-center justify-center bg-white min-h-[300px]">
             <div className="h-16 w-16 bg-slate-50 rounded-full flex items-center justify-center mb-4">
              <Wallet className="h-8 w-8 text-slate-300" />
            </div>
            <h4 className="font-bold text-slate-700">All riders are paid out</h4>
            <p className="text-sm text-slate-500 mt-1">No pending balances in the ledger.</p>
          </div>
        </Card>
      </div>
    </motion.div>
  )
}
