"use client"

import {
  LayoutDashboard,
  Utensils,
  Map,
  Ticket,
  Image as ImageIcon,
  Users,
  Settings,
  CircleDollarSign,
  Briefcase
} from "lucide-react"
import Link from "next/link"
import { usePathname } from "next/navigation"

const navItems = [
  { url: "/", icon: LayoutDashboard },
  { url: "/orders", icon: Briefcase },
  { url: "/menu", icon: Utensils },
  { url: "/customers", icon: Users },
  { url: "/zones", icon: Map },
  { url: "/coupons", icon: Ticket },
  { url: "/financials", icon: CircleDollarSign },
  { url: "/settings", icon: Settings },
]

export function AppSidebar() {
  const pathname = usePathname()

  return (
    <aside className="w-[80px] flex-col items-center py-6 bg-white border-r border-slate-100 shadow-[10px_0_30px_rgba(0,0,0,0.02)] hidden md:flex shrink-0 z-30 sticky top-0 h-screen">
      <div className="mb-8">
        <div className="w-10 h-10 bg-gradient-to-br from-rose-400 to-red-500 rounded-2xl flex items-center justify-center shadow-lg shadow-red-500/30 transform rotate-12">
          <Utensils className="h-5 w-5 text-white -rotate-12" />
        </div>
      </div>

      <nav className="flex flex-col gap-6 flex-1 w-full items-center">
        {navItems.map((item, index) => {
          const isActive = pathname === item.url || (item.url !== "/" && pathname?.startsWith(item.url))
          return (
            <Link key={index} href={item.url} className="relative group">
              <div className={`p-3 rounded-2xl transition-all duration-300 ${isActive ? 'bg-red-50 text-red-500 shadow-sm' : 'text-slate-400 hover:text-slate-700 hover:bg-slate-50'}`}>
                <item.icon className={`h-5 w-5 ${isActive ? 'fill-red-100' : ''}`} />
              </div>
              {isActive && (
                <div className="absolute -left-4 top-1/2 -translate-y-1/2 w-1 h-6 bg-red-500 rounded-r-full shadow-[0_0_10px_rgba(239,68,68,0.5)]" />
              )}
            </Link>
          )
        })}
      </nav>
      
      <div className="mt-auto pt-6 border-t border-slate-100 w-full flex justify-center">
        <button className="p-3 text-slate-400 hover:text-slate-700 hover:bg-slate-50 rounded-2xl transition-all">
          <Settings className="h-5 w-5" />
        </button>
      </div>
    </aside>
  )
}
