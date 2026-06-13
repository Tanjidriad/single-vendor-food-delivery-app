"use client"

import { ColumnDef } from "@tanstack/react-table"
import { Badge } from "@/components/ui/badge"
import { MoreHorizontal, Ban, CheckCircle, CarFront } from "lucide-react"
import { Button } from "@/components/ui/button"
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"

export type RiderRow = {
  id: string
  fullName: string
  phone: string
  vehicleType: string | null
  isOnline: boolean
  approvalStatus: string
  ratingAvg: number
  totalDeliveries: number
}

export const columns: ColumnDef<RiderRow>[] = [
  {
    accessorKey: "fullName",
    header: "Rider",
    cell: ({ row }) => {
      const rider = row.original
      return (
        <div className="flex flex-col">
          <span className="font-medium text-foreground">{rider.fullName}</span>
          <span className="text-xs text-muted-foreground">{rider.phone}</span>
        </div>
      )
    },
  },
  {
    accessorKey: "vehicleType",
    header: "Vehicle",
    cell: ({ row }) => (
      <div className="flex items-center gap-2 text-muted-foreground">
        <CarFront className="h-4 w-4" />
        <span className="capitalize">{row.getValue("vehicleType") || "N/A"}</span>
      </div>
    ),
  },
  {
    accessorKey: "approvalStatus",
    header: "Approval",
    cell: ({ row }) => {
      const status = row.getValue("approvalStatus") as string
      const isApproved = status === "APPROVED"
      const isPending = status === "PENDING"
      
      return (
        <Badge 
          variant="outline" 
          className={`font-normal ${
            isApproved ? "border-success/30 text-success bg-success/10" : 
            isPending ? "border-warning/30 text-warning bg-warning/10" : 
            "border-destructive/30 text-destructive bg-destructive/10"
          }`}
        >
          {status}
        </Badge>
      )
    },
  },
  {
    accessorKey: "isOnline",
    header: "Status",
    cell: ({ row }) => {
      const isOnline = row.getValue("isOnline") as boolean
      return (
        <div className="flex items-center gap-2">
          <span className={`h-2 w-2 rounded-full ${isOnline ? 'bg-success glow-success' : 'bg-muted'}`} />
          <span className="text-sm text-muted-foreground">{isOnline ? 'Online' : 'Offline'}</span>
        </div>
      )
    },
  },
  {
    accessorKey: "ratingAvg",
    header: "Rating",
    cell: ({ row }) => (
      <span className="tabular-nums font-medium text-amber-500">
        ★ {Number(row.getValue("ratingAvg")).toFixed(1)}
      </span>
    ),
  },
  {
    accessorKey: "totalDeliveries",
    header: "Deliveries",
    cell: ({ row }) => (
      <span className="tabular-nums text-muted-foreground">{row.getValue("totalDeliveries")}</span>
    ),
  },
  {
    id: "actions",
    cell: ({ row }) => {
      const rider = row.original
      const isPending = rider.approvalStatus === "PENDING"

      return (
        <DropdownMenu>
          <DropdownMenuTrigger className="inline-flex items-center justify-center rounded-md text-sm font-medium transition-colors hover:bg-accent hover:text-accent-foreground h-8 w-8 p-0">
            <span className="sr-only">Open menu</span>
            <MoreHorizontal className="h-4 w-4" />
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end" className="bg-white border-slate-100 shadow-xl rounded-xl w-48">
            <DropdownMenuLabel>Actions</DropdownMenuLabel>
            <DropdownMenuItem className="cursor-pointer">
              View Profile & Docs
            </DropdownMenuItem>
            <DropdownMenuSeparator />
            {isPending && (
              <>
                <DropdownMenuItem className="cursor-pointer text-success focus:text-success focus:bg-success/10">
                  <CheckCircle className="mr-2 h-4 w-4" />
                  Approve Rider
                </DropdownMenuItem>
                <DropdownMenuItem className="cursor-pointer text-destructive focus:text-destructive focus:bg-destructive/10">
                  <Ban className="mr-2 h-4 w-4" />
                  Reject Rider
                </DropdownMenuItem>
              </>
            )}
          </DropdownMenuContent>
        </DropdownMenu>
      )
    },
  },
]
