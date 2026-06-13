"use client"

import { ColumnDef } from "@tanstack/react-table"
import { Badge } from "@/components/ui/badge"
import { MoreHorizontal, Edit, Trash } from "lucide-react"
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"
import { formatCurrency } from "@/lib/utils"

// ----------------- Categories -----------------
export type CategoryRow = {
  id: string
  name: string
  description: string
  sortOrder: number
  isActive: boolean
  imageUrl: string
}

export const categoryColumns: ColumnDef<CategoryRow>[] = [
  {
    accessorKey: "name",
    header: "Category Name",
    cell: ({ row }) => (
      <div className="flex flex-col">
        <span className="font-bold text-slate-800">{row.getValue("name")}</span>
        <span className="text-xs text-slate-500 truncate max-w-[200px]">
          {row.original.description || "No description"}
        </span>
      </div>
    ),
  },
  {
    accessorKey: "sortOrder",
    header: "Sort Order",
    cell: ({ row }) => <span className="font-medium text-slate-600">{row.getValue("sortOrder")}</span>
  },
  {
    accessorKey: "isActive",
    header: "Status",
    cell: ({ row }) => {
      const isActive = row.getValue("isActive") as boolean
      return (
        <Badge variant="outline" className={isActive ? "border-0 text-emerald-600 bg-emerald-100 font-bold" : "border-0 text-rose-600 bg-rose-100 font-bold"}>
          {isActive ? "ACTIVE" : "INACTIVE"}
        </Badge>
      )
    },
  },
  {
    id: "actions",
    cell: ({ row }) => (
      <DropdownMenu>
        <DropdownMenuTrigger className="inline-flex items-center justify-center rounded-md text-sm transition-colors hover:bg-slate-100 text-slate-500 hover:text-slate-800 h-8 w-8 p-0">
          <MoreHorizontal className="h-4 w-4" />
        </DropdownMenuTrigger>
        <DropdownMenuContent align="end" className="bg-white border-slate-100 shadow-xl w-32 rounded-xl">
          <DropdownMenuItem className="cursor-pointer font-medium text-slate-700 hover:bg-slate-50"><Edit className="mr-2 h-4 w-4" /> Edit</DropdownMenuItem>
          <DropdownMenuItem className="cursor-pointer font-medium text-rose-600 focus:text-rose-700 focus:bg-rose-50"><Trash className="mr-2 h-4 w-4" /> Delete</DropdownMenuItem>
        </DropdownMenuContent>
      </DropdownMenu>
    ),
  },
]

// ----------------- Items -----------------
export type ItemRow = {
  id: string
  categoryId: string
  name: string
  description: string
  price: number
  compareAtPrice: number | null
  isAvailable: boolean
  isFeatured: boolean
  sortOrder: number
  tags: string[]
}

export const itemColumns: ColumnDef<ItemRow>[] = [
  {
    accessorKey: "name",
    header: "Item Name",
    cell: ({ row }) => (
      <div className="flex flex-col">
        <span className="font-bold text-slate-800 flex items-center gap-2">
          {row.getValue("name")}
          {row.original.isFeatured && <Badge className="bg-amber-100 text-amber-600 border-none px-2 py-0.5 text-[10px] font-black uppercase tracking-wider">Featured</Badge>}
        </span>
        <span className="text-xs text-slate-500 truncate max-w-[200px]">
          {row.original.description || "No description"}
        </span>
      </div>
    ),
  },
  {
    accessorKey: "price",
    header: "Price",
    cell: ({ row }) => (
      <div className="flex flex-col">
        <span className="tabular-nums font-bold text-slate-800">
          {formatCurrency(row.getValue("price"))}
        </span>
        {row.original.compareAtPrice && (
          <span className="tabular-nums text-xs font-medium text-slate-400 line-through">
            {formatCurrency(row.original.compareAtPrice)}
          </span>
        )}
      </div>
    ),
  },
  {
    accessorKey: "isAvailable",
    header: "Status",
    cell: ({ row }) => {
      const isAvail = row.getValue("isAvailable") as boolean
      return (
        <Badge variant="outline" className={isAvail ? "border-0 text-emerald-600 bg-emerald-100 font-bold" : "border-0 text-rose-600 bg-rose-100 font-bold"}>
          {isAvail ? "AVAILABLE" : "UNAVAILABLE"}
        </Badge>
      )
    },
  },
  {
    id: "actions",
    cell: ({ row }) => (
      <DropdownMenu>
        <DropdownMenuTrigger className="inline-flex items-center justify-center rounded-md text-sm transition-colors hover:bg-slate-100 text-slate-500 hover:text-slate-800 h-8 w-8 p-0">
          <MoreHorizontal className="h-4 w-4" />
        </DropdownMenuTrigger>
        <DropdownMenuContent align="end" className="bg-white border-slate-100 shadow-xl w-32 rounded-xl">
          <DropdownMenuItem className="cursor-pointer font-medium text-slate-700 hover:bg-slate-50"><Edit className="mr-2 h-4 w-4" /> Edit</DropdownMenuItem>
          <DropdownMenuItem className="cursor-pointer font-medium text-rose-600 focus:text-rose-700 focus:bg-rose-50"><Trash className="mr-2 h-4 w-4" /> Delete</DropdownMenuItem>
        </DropdownMenuContent>
      </DropdownMenu>
    ),
  },
]

// ----------------- Addons -----------------
export type AddonRow = {
  id: string
  name: string
  price: number
  isActive: boolean
}

export const addonColumns: ColumnDef<AddonRow>[] = [
  {
    accessorKey: "name",
    header: "Addon Name",
    cell: ({ row }) => <span className="font-bold text-slate-800">{row.getValue("name")}</span>,
  },
  {
    accessorKey: "price",
    header: "Price",
    cell: ({ row }) => (
      <span className="tabular-nums font-bold text-slate-800">
        {formatCurrency(row.getValue("price"))}
      </span>
    ),
  },
  {
    accessorKey: "isActive",
    header: "Status",
    cell: ({ row }) => {
      const isActive = row.getValue("isActive") as boolean
      return (
        <Badge variant="outline" className={isActive ? "border-0 text-emerald-600 bg-emerald-100 font-bold" : "border-0 text-rose-600 bg-rose-100 font-bold"}>
          {isActive ? "ACTIVE" : "INACTIVE"}
        </Badge>
      )
    },
  },
  {
    id: "actions",
    cell: ({ row }) => (
      <DropdownMenu>
        <DropdownMenuTrigger className="inline-flex items-center justify-center rounded-md text-sm transition-colors hover:bg-slate-100 text-slate-500 hover:text-slate-800 h-8 w-8 p-0">
          <MoreHorizontal className="h-4 w-4" />
        </DropdownMenuTrigger>
        <DropdownMenuContent align="end" className="bg-white border-slate-100 shadow-xl w-32 rounded-xl">
          <DropdownMenuItem className="cursor-pointer font-medium text-slate-700 hover:bg-slate-50"><Edit className="mr-2 h-4 w-4" /> Edit</DropdownMenuItem>
          <DropdownMenuItem className="cursor-pointer font-medium text-rose-600 focus:text-rose-700 focus:bg-rose-50"><Trash className="mr-2 h-4 w-4" /> Delete</DropdownMenuItem>
        </DropdownMenuContent>
      </DropdownMenu>
    ),
  },
]
