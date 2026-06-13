"use client"

import { useQuery } from "@tanstack/react-query"
import { fetchClient } from "@/lib/api/client"
import { RevenueChart } from "@/components/dashboard/revenue-chart"
import { Search, MapPin, Clock, Plus, Star } from "lucide-react"
import { Input } from "@/components/ui/input"

export default function DashboardPage() {
  const { data: statsData } = useQuery({
    queryKey: ['admin-stats'],
    queryFn: () => fetchClient<any>('/admin/super/stats'),
  })

  const { data: revenueData } = useQuery({
    queryKey: ['admin-revenue-chart'],
    queryFn: () => fetchClient<any>('/admin/super/revenue'),
  })

  // Format real revenue data for the chart
  const formattedRevenue = revenueData?.map((item: any) => ({
    name: new Date(item.date).toLocaleDateString('en-US', { weekday: 'short' }),
    total: item.revenue
  })) || []

  const { data: popularItems, isLoading: isPopularLoading } = useQuery({
    queryKey: ['admin-popular-items'],
    queryFn: () => fetchClient<any[]>('/reports/popular-items'),
  })

  return (
    <div className="space-y-8 pb-10">
      
      {/* 1. Top Stat Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        
        {/* Preparing Card */}
        <div className="bg-white rounded-3xl p-6 shadow-[0_4px_25px_rgba(0,0,0,0.03)] border border-slate-50 relative overflow-hidden group hover:shadow-[0_8px_30px_rgba(0,0,0,0.06)] transition-all">
          <h2 className="text-4xl font-black text-slate-800">{statsData?.activeOrders || 0}</h2>
          <p className="text-slate-500 font-medium mt-1">Active Orders</p>
          <p className="text-emerald-500 font-bold text-sm mt-8">Tracking Live</p>
          <div className="absolute right-0 bottom-0 text-8xl translate-x-4 translate-y-4 group-hover:scale-110 transition-transform origin-bottom-right">
            🍕
          </div>
        </div>

        {/* Out for Delivery Card */}
        <div className="bg-white rounded-3xl p-6 shadow-[0_4px_25px_rgba(0,0,0,0.03)] border border-slate-50 relative overflow-hidden group hover:shadow-[0_8px_30px_rgba(0,0,0,0.06)] transition-all">
          <h2 className="text-4xl font-black text-slate-800">{statsData?.onlineRiders || 0}</h2>
          <p className="text-slate-500 font-medium mt-1">Online Riders</p>
          <p className="text-emerald-500 font-bold text-sm mt-8">Available Fleet</p>
          <div className="absolute right-0 bottom-0 text-8xl translate-x-2 translate-y-4 group-hover:scale-110 transition-transform origin-bottom-right">
            🛵
          </div>
        </div>

        {/* Delivered Card */}
        <div className="bg-white rounded-3xl p-6 shadow-[0_4px_25px_rgba(0,0,0,0.03)] border border-slate-50 relative overflow-hidden group hover:shadow-[0_8px_30px_rgba(0,0,0,0.06)] transition-all">
          <h2 className="text-4xl font-black text-slate-800">{statsData?.deliveredOrders || 0}</h2>
          <p className="text-slate-500 font-medium mt-1">Delivered Today</p>
          <p className="text-emerald-500 font-bold text-sm mt-8">Completed</p>
          <div className="absolute right-4 bottom-2 text-8xl translate-y-2 group-hover:scale-110 transition-transform origin-bottom-right">
            🛍️
          </div>
        </div>
      </div>

      {/* 2. Middle Row: Tracking & Trends */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        
        {/* Delivery Tracking Map Placeholder */}
        <div className="bg-white rounded-3xl p-6 shadow-[0_4px_25px_rgba(0,0,0,0.03)] border border-slate-50 flex flex-col h-[320px]">
          <div className="flex justify-between items-center mb-4">
            <h3 className="font-bold text-lg text-slate-800 flex items-center gap-2">
              <span className="w-2.5 h-2.5 bg-red-500 rounded-full"></span>
              Delivery Tracking
            </h3>
            <div className="flex items-center gap-2 text-red-500 font-semibold text-sm bg-red-50 px-3 py-1.5 rounded-full border border-red-100">
              <Clock className="w-4 h-4" />
              Estimated Time : 18 mins
            </div>
          </div>
          <div className="flex-1 rounded-2xl bg-slate-100 overflow-hidden relative border border-slate-200">
             <div className="absolute inset-0 bg-[url('https://maps.googleapis.com/maps/api/staticmap?center=23.8103,90.4125&zoom=14&size=600x300&maptype=roadmap&style=feature:all|element:labels.text.fill|color:0x8e8e8e&style=feature:all|element:labels.text.stroke|visibility:off&style=feature:landscape|element:geometry|color:0xf5f5f5&style=feature:poi|element:geometry|color:0xeeeeee&style=feature:road.highway|element:geometry|color:0xffffff&style=feature:road.local|element:geometry|color:0xffffff&style=feature:water|element:geometry|color:0xc9c9c9')] bg-cover bg-center opacity-80" />
             
             {/* Fake Route SVG */}
             <svg className="absolute inset-0 w-full h-full pointer-events-none" viewBox="0 0 400 200" preserveAspectRatio="none">
               <path d="M 50 150 Q 150 150 200 100 T 350 50" fill="none" stroke="#ef4444" strokeWidth="4" strokeLinecap="round" strokeDasharray="8 8" className="animate-[dash_20s_linear_infinite]" />
             </svg>
             <div className="absolute top-[40px] left-[340px] text-4xl">🏠</div>
             <div className="absolute top-[90px] left-[190px] text-4xl animate-bounce">🛵</div>
          </div>
        </div>

        {/* Order Trends */}
        <div className="bg-white rounded-3xl p-6 shadow-[0_4px_25px_rgba(0,0,0,0.03)] border border-slate-50 flex flex-col h-[320px]">
          <div className="flex justify-between items-center mb-4">
            <div>
              <h3 className="font-bold text-lg text-slate-800">Order Trends</h3>
              <p className="text-emerald-500 font-bold text-sm">+12.5% this month</p>
            </div>
            <select className="bg-slate-50 border border-slate-200 text-slate-600 rounded-full px-4 py-2 text-sm font-medium outline-none focus:ring-2 focus:ring-red-200 cursor-pointer">
              <option>Monthly</option>
              <option>Weekly</option>
            </select>
          </div>
          <div className="flex-1 mt-2 min-h-0">
            <RevenueChart data={formattedRevenue} />
          </div>
        </div>

      </div>

      {/* 3. Popular Items Grid */}
      <div className="bg-transparent mt-10">
        <div className="flex justify-between items-center mb-6">
          <h3 className="font-bold text-xl text-slate-800">Popular Items</h3>
          
          <div className="flex items-center gap-4">
            <div className="relative hidden md:block w-64">
              <Search className="absolute left-4 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-400" />
              <Input
                type="search"
                placeholder="Search menu items..."
                className="w-full bg-white border-0 pl-11 h-11 rounded-full text-slate-700 shadow-[0_2px_15px_rgba(0,0,0,0.04)]"
              />
            </div>
            <button className="flex items-center gap-2 bg-gradient-to-r from-red-400 to-rose-400 text-white px-5 py-2.5 rounded-full font-bold text-sm shadow-md shadow-red-500/20 hover:shadow-red-500/40 transition-shadow">
              <Plus className="w-4 h-4" /> Add to Menu
            </button>
          </div>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
          {isPopularLoading ? (
            <div className="col-span-full py-10 flex justify-center text-slate-400">Loading popular items...</div>
          ) : popularItems?.length ? (
            popularItems.map((item: any, index: number) => {
              const colors = ['bg-orange-50', 'bg-pink-50', 'bg-teal-50', 'bg-amber-50']
              const hoverColors = ['group-hover:bg-orange-100', 'group-hover:bg-pink-100', 'group-hover:bg-teal-100', 'group-hover:bg-amber-100']
              const color = colors[index % colors.length]
              const hoverColor = hoverColors[index % hoverColors.length]
              return (
                <div key={item.id} className="bg-white rounded-3xl p-4 shadow-[0_4px_20px_rgba(0,0,0,0.03)] border border-slate-50 group hover:-translate-y-1 transition-transform">
                  <div className={`${color} rounded-2xl h-40 mb-4 relative flex items-center justify-center overflow-hidden ${hoverColor} transition-colors`}>
                    <div className="absolute top-3 left-3 bg-white px-2 py-1 rounded-lg flex items-center gap-1 shadow-sm z-10">
                      <span className="text-xs font-bold text-slate-700">🔥 {item.totalSales} Sold</span>
                    </div>
                    {item.imageUrl ? (
                      <img src={item.imageUrl} alt={item.name} className="w-full h-full object-cover transform group-hover:scale-110 transition-transform" />
                    ) : (
                      <div className="text-8xl transform group-hover:scale-110 transition-transform">🍔</div>
                    )}
                  </div>
                  <h4 className="font-bold text-slate-800 text-lg">{item.name}</h4>
                  <p className="text-xs text-slate-400 mt-1 line-clamp-2">{item.description}</p>
                  <div className="flex items-center justify-between mt-4">
                    <div className="flex items-baseline gap-2">
                      <span className="font-black text-lg text-slate-800">৳{item.price}</span>
                    </div>
                  </div>
                </div>
              )
            })
          ) : (
             <div className="col-span-full py-10 flex justify-center text-slate-400">No sales data available yet.</div>
          )}
        </div>
      </div>

    </div>
  )
}
