"use client"

import { Bell, Search, ShoppingCart, Home, Briefcase, Car, Plane, Utensils, Box, BarChart2, FileText } from "lucide-react"
import { Input } from "@/components/ui/input"

const topNav = [
  { name: "Dashboard", icon: Home, url: "/" },
  { name: "Live Orders", icon: Briefcase, url: "/orders" },
  { name: "Menu", icon: Utensils, active: true, url: "/menu" },
  { name: "Financials", icon: BarChart2, url: "/financials" },
]

export function Header() {
  return (
    <header className="sticky top-0 z-20 flex h-20 items-center justify-between bg-white px-8 shadow-[0_4px_20px_rgba(0,0,0,0.02)]">
      
      {/* Search Bar - styled exactly like the reference */}
      <div className="w-[300px]">
        <div className="relative">
          <Search className="absolute left-4 top-1/2 -translate-y-1/2 h-5 w-5 text-slate-400" />
          <Input
            type="search"
            placeholder="Search menu items or orders..."
            className="w-full bg-slate-50 border-0 pl-12 h-12 rounded-full text-slate-700 placeholder:text-slate-400 focus-visible:ring-1 focus-visible:ring-red-200 shadow-inner text-sm font-medium"
          />
        </div>
      </div>

      {/* Top Nav Pills */}
      <div className="hidden lg:flex items-center gap-2">
        {topNav.map((item) => (
          <button
            key={item.name}
            className={`flex items-center gap-2 px-4 py-2.5 rounded-full text-sm font-bold transition-all duration-300 ${
              item.active 
                ? 'bg-gradient-to-r from-red-400 to-rose-400 text-white shadow-md shadow-red-500/20' 
                : 'text-slate-500 hover:bg-slate-50 hover:text-slate-800'
            }`}
          >
            <item.icon className="h-4 w-4" />
            {item.name}
          </button>
        ))}
      </div>

      {/* Right Icons */}
      <div className="flex items-center gap-4">
        <button className="h-12 w-12 rounded-full border border-slate-100 bg-white flex items-center justify-center text-slate-500 hover:bg-slate-50 transition-colors shadow-sm relative">
          <Bell className="h-5 w-5" />
          <span className="absolute top-3 right-3 w-2 h-2 bg-red-500 rounded-full border-2 border-white"></span>
        </button>
        <div className="h-12 w-12 rounded-full bg-slate-200 overflow-hidden border-2 border-white shadow-md cursor-pointer ml-2">
          <img src="https://i.pravatar.cc/100?img=11" alt="Profile" className="w-full h-full object-cover" />
        </div>
      </div>
    </header>
  )
}
