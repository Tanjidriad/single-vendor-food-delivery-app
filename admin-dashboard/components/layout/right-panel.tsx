"use client"

import { useQuery } from "@tanstack/react-query"
import { fetchClient } from "@/lib/api/client"
import { MapPin, Clock } from "lucide-react"
import Link from "next/link"

export function RightPanel() {
  const { data: orders } = useQuery({
    queryKey: ['admin-super-orders-recent'],
    queryFn: () => fetchClient<any>('/admin/super/orders'),
  })

  return (
    <aside className="hidden xl:flex flex-col w-80 bg-white border-l border-slate-100 h-screen sticky top-0 shrink-0 shadow-[-10px_0_30px_rgba(0,0,0,0.02)] z-20">
      {/* Map Tracking Placeholder */}
      <div className="h-[280px] w-full relative bg-slate-100 overflow-hidden shrink-0">
        <div className="absolute inset-0 bg-[url('https://maps.googleapis.com/maps/api/staticmap?center=23.8103,90.4125&zoom=13&size=400x400&maptype=roadmap&style=feature:all|element:labels.text.fill|color:0x8e8e8e&style=feature:all|element:labels.text.stroke|visibility:off&style=feature:landscape|element:geometry|color:0xf5f5f5&style=feature:poi|element:geometry|color:0xeeeeee&style=feature:road.highway|element:geometry|color:0xffffff&style=feature:road.local|element:geometry|color:0xffffff&style=feature:water|element:geometry|color:0xc9c9c9')] bg-cover bg-center opacity-80" />
        
        {/* Fake Map Pins */}
        <div className="absolute top-1/4 left-1/4 bg-white p-1 rounded-full shadow-lg">
          <img src="https://i.pravatar.cc/100?img=1" className="w-8 h-8 rounded-full" />
          <div className="absolute -bottom-1 left-1/2 -translate-x-1/2 w-2 h-2 bg-white rotate-45" />
          <div className="absolute -bottom-1 left-1/2 -translate-x-1/2 w-2 h-2 bg-red-500 rounded-full scale-50" />
        </div>
        <div className="absolute top-1/2 right-1/4 bg-white p-1 rounded-full shadow-lg">
          <img src="https://i.pravatar.cc/100?img=3" className="w-8 h-8 rounded-full" />
          <div className="absolute -bottom-1 left-1/2 -translate-x-1/2 w-2 h-2 bg-white rotate-45" />
          <div className="absolute -bottom-1 left-1/2 -translate-x-1/2 w-2 h-2 bg-red-500 rounded-full scale-50" />
        </div>
      </div>

      <div className="flex-1 overflow-y-auto custom-scrollbar p-6 bg-slate-50/50">
        <h3 className="font-bold text-lg text-slate-800 mb-4 px-2">Recent Orders</h3>
        <div className="space-y-4">
          {orders?.data?.slice(0, 3).map((order: any, i: number) => (
            <div key={order.id} className="bg-white rounded-2xl p-4 shadow-[0_4px_20px_rgba(0,0,0,0.03)] border border-slate-100 hover:shadow-[0_4px_25px_rgba(0,0,0,0.06)] transition-all">
              <div className="flex justify-between items-start mb-3">
                <div className="flex items-center gap-3">
                  <img src={`https://i.pravatar.cc/100?img=${i + 10}`} className="w-10 h-10 rounded-full" />
                  <div>
                    <h4 className="font-bold text-sm text-slate-800">{order.customerName}</h4>
                    <p className="text-[11px] text-slate-500 font-medium bg-slate-100 px-2 py-0.5 rounded-full inline-block mt-1">#{order.orderNumber}</p>
                  </div>
                </div>
                <Link href="/orders" className="text-[11px] font-bold text-slate-700 bg-slate-100 px-3 py-1.5 rounded-full hover:bg-slate-200 transition-colors">
                  View Details
                </Link>
              </div>

              <div className="space-y-3 pt-3 border-t border-slate-50">
                {order.items?.map((item: any) => (
                  <div key={item.id} className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-full bg-slate-50 flex items-center justify-center shrink-0">
                      🍽️
                    </div>
                    <div className="flex-1 min-w-0">
                      <h5 className="font-bold text-sm text-slate-700 truncate">{item.name}</h5>
                      <p className="text-xs text-slate-400">{item.quantity}x</p>
                    </div>
                    <p className="font-bold text-sm text-slate-800">৳{item.lineTotal}</p>
                  </div>
                ))}
              </div>
              
              <div className="pt-3 mt-3 border-t border-slate-50 flex justify-between items-center">
                <p className="text-xs font-bold text-slate-500">Total</p>
                <p className="font-black text-sm text-emerald-600">৳{order.grandTotal}</p>
              </div>
            </div>
          ))}
        </div>
      </div>
    </aside>
  )
}
