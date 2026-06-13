"use client"

import { useState } from "react"
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog"
import { Clock, MapPin, Navigation } from "lucide-react"

interface TrackOrderDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  order: {
    orderNumber: string
    status: string
    riderName: string | null
  }
}

export function TrackOrderDialog({ open, onOpenChange, order }: TrackOrderDialogProps) {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[600px] bg-slate-50 border-slate-100 p-0 overflow-hidden rounded-[24px]">
        <div className="bg-white p-6 pb-4 border-b border-slate-100">
          <DialogHeader>
            <DialogTitle className="text-xl font-black text-slate-800 flex items-center gap-2">
              <span className="w-2.5 h-2.5 bg-red-500 rounded-full animate-pulse"></span>
              Live Tracking - #{order.orderNumber}
            </DialogTitle>
          </DialogHeader>
          <div className="flex items-center gap-4 mt-4">
            <div className="flex items-center gap-2 bg-slate-50 px-3 py-1.5 rounded-full text-sm font-semibold text-slate-600 border border-slate-100">
              <Navigation className="w-4 h-4 text-blue-500" />
              {order.riderName || "Assigning Rider..."}
            </div>
            <div className="flex items-center gap-2 bg-red-50 px-3 py-1.5 rounded-full text-sm font-semibold text-red-500 border border-red-100">
              <Clock className="w-4 h-4" />
              Est. Time : 18 mins
            </div>
          </div>
        </div>

        {/* Map Area */}
        <div className="h-[350px] w-full relative bg-slate-100 overflow-hidden border-t border-slate-200">
          <div className="absolute inset-0 bg-[url('https://maps.googleapis.com/maps/api/staticmap?center=23.8103,90.4125&zoom=14&size=600x400&maptype=roadmap&style=feature:all|element:labels.text.fill|color:0x8e8e8e&style=feature:all|element:labels.text.stroke|visibility:off&style=feature:landscape|element:geometry|color:0xf5f5f5&style=feature:poi|element:geometry|color:0xeeeeee&style=feature:road.highway|element:geometry|color:0xffffff&style=feature:road.local|element:geometry|color:0xffffff&style=feature:water|element:geometry|color:0xc9c9c9')] bg-cover bg-center opacity-80" />
          
          {/* Fake Route SVG */}
          <svg className="absolute inset-0 w-full h-full pointer-events-none" viewBox="0 0 400 200" preserveAspectRatio="none">
            <path d="M 50 150 Q 150 150 200 100 T 350 50" fill="none" stroke="#ef4444" strokeWidth="4" strokeLinecap="round" strokeDasharray="8 8" className="animate-[dash_20s_linear_infinite]" />
          </svg>
          <div className="absolute top-[80px] left-[440px] text-5xl drop-shadow-lg">🏠</div>
          <div className="absolute top-[160px] left-[190px] text-5xl animate-bounce drop-shadow-xl">🛵</div>
          
          {/* Status Overlay */}
          <div className="absolute bottom-6 left-1/2 -translate-x-1/2 bg-white/90 backdrop-blur-md px-6 py-3 rounded-2xl shadow-xl border border-slate-100 flex items-center gap-4">
            <div className="w-10 h-10 rounded-full bg-red-100 flex items-center justify-center">
              <MapPin className="w-5 h-5 text-red-500" />
            </div>
            <div>
              <p className="text-xs font-bold text-slate-400 uppercase tracking-wider">Current Status</p>
              <p className="text-sm font-black text-slate-800">{order.status.replace(/_/g, ' ')}</p>
            </div>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  )
}
