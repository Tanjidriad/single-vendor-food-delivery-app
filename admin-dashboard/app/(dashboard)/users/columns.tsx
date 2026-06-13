"use client"

import { ColumnDef } from "@tanstack/react-table"
import { Badge } from "@/components/ui/badge"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { MoreHorizontal, Ban, CheckCircle, Eye } from "lucide-react"
import { Button } from "@/components/ui/button"
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"
import { formatDate, getInitials } from "@/lib/utils"

export type UserRow = {
  id: string
  name: string
  email: string
  phone: string | null
  role: string
  status: string
  createdAt: string
  totalOrders: number
  avatarUrl: string | null
}

export const columns: ColumnDef<UserRow>[] = [
  {
    accessorKey: "name",
    header: "User",
    cell: ({ row }) => {
      const user = row.original
      return (
        <div className="flex items-center gap-3">
          <Avatar className="h-9 w-9 border border-border/50">
            <AvatarImage src={user.avatarUrl || ""} alt={user.name} />
            <AvatarFallback className="bg-primary/10 text-primary font-medium text-xs">
              {getInitials(user.name)}
            </AvatarFallback>
          </Avatar>
          <div className="flex flex-col">
            <span className="font-medium text-foreground">{user.name}</span>
            <span className="text-xs text-muted-foreground">{user.email}</span>
          </div>
        </div>
      )
    },
  },
  {
    accessorKey: "role",
    header: "Role",
    cell: ({ row }) => {
      const role = row.getValue("role") as string
      return (
        <Badge variant="outline" className="bg-secondary/50 font-normal">
          {role}
        </Badge>
      )
    },
  },
  {
    accessorKey: "status",
    header: "Status",
    cell: ({ row }) => {
      const status = row.getValue("status") as string
      const isSus = status === "SUSPENDED"
      const isAct = status === "ACTIVE"
      return (
        <Badge 
          variant="outline" 
          className={`font-normal ${
            isAct ? "border-success/30 text-success bg-success/10" : 
            isSus ? "border-destructive/30 text-destructive bg-destructive/10" : 
            "border-warning/30 text-warning bg-warning/10"
          }`}
        >
          {status}
        </Badge>
      )
    },
  },
  {
    accessorKey: "totalOrders",
    header: "Orders",
    cell: ({ row }) => (
      <span className="tabular-nums font-medium">{row.getValue("totalOrders")}</span>
    ),
  },
  {
    accessorKey: "createdAt",
    header: "Joined",
    cell: ({ row }) => (
      <span className="text-muted-foreground whitespace-nowrap">
        {formatDate(row.getValue("createdAt"))}
      </span>
    ),
  },
  {
    id: "actions",
    cell: ({ row }) => {
      const user = row.original
      const isSuspended = user.status === "SUSPENDED"

      return (
        <DropdownMenu>
          <DropdownMenuTrigger className="inline-flex items-center justify-center rounded-md text-sm font-medium transition-colors hover:bg-accent hover:text-accent-foreground h-8 w-8 p-0">
            <span className="sr-only">Open menu</span>
            <MoreHorizontal className="h-4 w-4" />
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end" className="bg-white border-slate-100 shadow-xl rounded-xl w-40">
            <DropdownMenuLabel>Actions</DropdownMenuLabel>
            <DropdownMenuItem className="cursor-pointer">
              <Eye className="mr-2 h-4 w-4" />
              View details
            </DropdownMenuItem>
            <DropdownMenuSeparator />
            {isSuspended ? (
              <DropdownMenuItem className="cursor-pointer text-success focus:text-success focus:bg-success/10">
                <CheckCircle className="mr-2 h-4 w-4" />
                Activate User
              </DropdownMenuItem>
            ) : (
              <DropdownMenuItem className="cursor-pointer text-destructive focus:text-destructive focus:bg-destructive/10">
                <Ban className="mr-2 h-4 w-4" />
                Suspend User
              </DropdownMenuItem>
            )}
          </DropdownMenuContent>
        </DropdownMenu>
      )
    },
  },
]
