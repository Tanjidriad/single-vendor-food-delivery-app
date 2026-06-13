"use client"

import { useState } from "react"
import { ColumnDef } from "@tanstack/react-table"
import { Badge } from "@/components/ui/badge"
import { MoreHorizontal, FileText, CheckCircle, ExternalLink, Eye, MapPin, AlertTriangle, ChevronDown } from "lucide-react"
import { Button } from "@/components/ui/button"
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"
import { format } from "date-fns"
import { TrackOrderDialog } from "./components/track-order-dialog"

export type OrderRow = {
  id: string
  orderNumber: string
  customerName: string
  status: string
  orderType: string
  grandTotal: number
  placedAt: string
  riderName: string | null
}

const getStatusBadge = (status: string) => {
  // Mapping to exactly match the solid color pills in the image
  switch (status) {
    case "PREPARING":
      return <Badge className="bg-blue-600 hover:bg-blue-700 text-white rounded-full px-4 py-1 text-[13px] font-medium border-0 shadow-sm shadow-blue-500/20">Cooking</Badge>
    case "PLACED":
    case "ACCEPTED":
      return <Badge className="bg-yellow-400 hover:bg-yellow-500 text-black rounded-full px-4 py-1 text-[13px] font-medium border-0 shadow-sm shadow-yellow-400/20">Pending</Badge>
    case "READY_FOR_PICKUP":
      return <Badge className="bg-green-600 hover:bg-green-700 text-white rounded-full px-4 py-1 text-[13px] font-medium border-0 shadow-sm shadow-green-500/20">Ready</Badge>
    case "DELIVERED":
    case "PICKED_UP":
    case "ON_THE_WAY":
      return <Badge className="bg-purple-600 hover:bg-purple-700 text-white rounded-full px-4 py-1 text-[13px] font-medium border-0 shadow-sm shadow-purple-500/20">Delivered</Badge>
    case "CANCELLED":
    case "REJECTED":
    case "DELIVERY_FAILED":
      return <Badge className="bg-red-600 hover:bg-red-700 text-white rounded-full px-4 py-1 text-[13px] font-medium border-0 shadow-sm shadow-red-500/20">Cancelled</Badge>
    default:
      return <Badge className="bg-slate-500 hover:bg-slate-600 text-white rounded-full px-4 py-1 text-[13px] font-medium border-0 shadow-sm">{status}</Badge>
  }
}

const getOrderTypeBadge = (type: string) => {
  if (type === "DELIVERY") {
    return <Badge className="bg-orange-500 hover:bg-orange-600 text-white rounded-full px-4 py-1 text-[13px] font-medium border-0 shadow-sm shadow-orange-500/20">Delivery</Badge>
  }
  // Treat PICKUP or DINE_IN as dark grey buttons like Dine-in, Takeaway, Parcel
  return <Badge className="bg-[#333] hover:bg-[#222] text-white rounded-full px-4 py-1 text-[13px] font-medium border-0 shadow-sm shadow-black/20">Takeaway</Badge>
}

export const columns: ColumnDef<OrderRow>[] = [
  {
    accessorKey: "orderNumber",
    header: "Order ID",
    cell: ({ row }) => (
      <span className="font-bold text-slate-800">Order #{row.getValue("orderNumber")}</span>
    ),
  },
  {
    accessorKey: "placedAt",
    header: "Time Placed",
    cell: ({ row }) => {
      const date = new Date(row.getValue("placedAt"))
      return (
        <span className="font-bold text-slate-700">{format(date, "hh:mm a")}</span>
      )
    },
  },
  {
    accessorKey: "status",
    header: () => (
      <div className="flex items-center gap-1 cursor-pointer hover:text-slate-700">
        Status <ChevronDown className="h-3 w-3" />
      </div>
    ),
    cell: ({ row }) => getStatusBadge(row.getValue("status") as string),
  },
  {
    accessorKey: "orderType",
    header: () => (
      <div className="flex items-center gap-1 cursor-pointer hover:text-slate-700">
        Order Type <ChevronDown className="h-3 w-3" />
      </div>
    ),
    cell: ({ row }) => getOrderTypeBadge(row.original.orderType || "PICKUP"),
  },
  {
    id: "priority",
    header: () => (
      <div className="flex items-center gap-1 cursor-pointer hover:text-slate-700">
        Priority <ChevronDown className="h-3 w-3" />
      </div>
    ),
    cell: ({ row }) => {
      const placedAt = new Date(row.original.placedAt)
      const diffMins = (new Date().getTime() - placedAt.getTime()) / (1000 * 60)
      const status = row.original.status
      
      // If it's been more than 30 mins and not delivered, mark as Urgent
      const isUrgent = diffMins > 30 && !["DELIVERED", "CANCELLED", "REJECTED"].includes(status)

      if (isUrgent) {
        return <Badge className="bg-[#FF4500] hover:bg-[#e63e00] text-white rounded-full px-4 py-1 text-[13px] font-medium border-0 shadow-sm shadow-[#FF4500]/20">Urgent</Badge>
      }
      return <Badge variant="outline" className="border-slate-300 text-slate-500 rounded-full px-4 py-1 text-[13px] font-medium bg-white">Normal</Badge>
    },
  },
  {
    id: "alert",
    header: "Alert",
    cell: ({ row }) => {
      const placedAt = new Date(row.original.placedAt)
      const diffMins = Math.floor((new Date().getTime() - placedAt.getTime()) / (1000 * 60))
      const status = row.original.status
      const isDelayed = diffMins > 30 && !["DELIVERED", "CANCELLED", "REJECTED"].includes(status)

      if (!isDelayed) {
        return (
          <div className="flex items-center gap-2 text-yellow-500/50">
            <span className="font-bold text-sm">Alert</span>
            <div className="h-6 w-6 rounded-full bg-yellow-500/20 text-yellow-600/50 flex items-center justify-center text-[10px] font-bold">01</div>
          </div>
        )
      }

      // Delayed: Show active alert with hover tooltip
      return (
        <div className="relative group flex items-center gap-2 text-yellow-500 cursor-pointer">
          <span className="font-bold text-sm">Alert</span>
          <div className="h-6 w-6 rounded-full bg-yellow-500 text-white flex items-center justify-center text-[10px] font-bold shadow-md shadow-yellow-500/30">01</div>
          
          {/* Custom Tooltip */}
          <div className="absolute bottom-full left-1/2 -translate-x-1/2 mb-2 w-48 opacity-0 group-hover:opacity-100 transition-opacity duration-200 pointer-events-none z-50">
            <div className="bg-[#FFF8E1] border border-yellow-200 rounded-xl p-3 shadow-xl flex flex-col items-center text-center">
              <AlertTriangle className="h-5 w-5 text-yellow-500 mb-1" />
              <p className="text-xs font-bold text-slate-700">This order Delayed by {diffMins - 30} mins</p>
              {/* Arrow */}
              <div className="absolute top-full left-1/2 -translate-x-1/2 -mt-[1px] border-8 border-transparent border-t-[#FFF8E1]"></div>
              <div className="absolute top-full left-1/2 -translate-x-1/2 mt-[1px] border-8 border-transparent border-t-yellow-200 -z-10"></div>
            </div>
          </div>
        </div>
      )
    },
  },
  {
    id: "details",
    header: "Order Details",
    cell: ({ row }) => (
      <span className="font-bold text-blue-600 hover:text-blue-700 cursor-pointer text-sm">Details</span>
    ),
  },
  {
    id: "actions",
    header: "Action",
    cell: ({ row }) => <OrderActionCell order={row.original} />,
  },
]

function OrderActionCell({ order }: { order: OrderRow }) {
  const [trackOpen, setTrackOpen] = useState(false)
  const isDelivered = order.status === "DELIVERED"
  const isCancelled = order.status === "CANCELLED" || order.status === "REJECTED"

  return (
    <>
      <DropdownMenu>
        <DropdownMenuTrigger className="inline-flex items-center justify-center rounded-md text-slate-800 transition-colors hover:bg-slate-100 h-8 w-8 p-0 font-bold tracking-widest leading-none outline-none">
          ....
        </DropdownMenuTrigger>
        <DropdownMenuContent align="end" className="bg-white border-slate-100 shadow-xl w-40 rounded-xl">
          <DropdownMenuItem className="cursor-pointer font-medium text-slate-700 hover:bg-slate-50"><Eye className="mr-2 h-4 w-4" /> View Details</DropdownMenuItem>
          <DropdownMenuItem 
            onSelect={() => setTrackOpen(true)} 
            className="cursor-pointer font-medium text-slate-700 hover:bg-slate-50"
          >
            <MapPin className="mr-2 h-4 w-4" /> Track Order
          </DropdownMenuItem>
          <DropdownMenuSeparator />
          {(!isDelivered && !isCancelled) && (
             <DropdownMenuItem className="cursor-pointer text-red-600 focus:text-red-700 focus:bg-red-50 font-medium">
               <CheckCircle className="mr-2 h-4 w-4" />
               Force Cancel
             </DropdownMenuItem>
          )}
          <DropdownMenuItem className="cursor-pointer font-medium text-slate-700 hover:bg-slate-50">
            <ExternalLink className="mr-2 h-4 w-4" />
            Trace Timeline
          </DropdownMenuItem>
        </DropdownMenuContent>
      </DropdownMenu>

      <TrackOrderDialog open={trackOpen} onOpenChange={setTrackOpen} order={order} />
    </>
  )
}
