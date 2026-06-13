"use client"

import { useQuery } from "@tanstack/react-query"
import { MenuSquare, Plus, Layers, Grid, Boxes } from "lucide-react"
import { fetchClient } from "@/lib/api/client"
import { Button } from "@/components/ui/button"
import { motion } from "framer-motion"
import { DataTable } from "@/components/tables/data-table"
import { categoryColumns, itemColumns, addonColumns } from "./columns"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog"
import {
  Sheet,
  SheetContent,
  SheetDescription,
  SheetHeader,
  SheetTitle,
  SheetTrigger,
} from "@/components/ui/sheet"

import { CategoryForm } from "./components/category-form"
import { ItemForm } from "./components/item-form"
import { AddonForm } from "./components/addon-form"

export default function MenuPage() {
  const { data, isLoading } = useQuery({
    queryKey: ['admin-menu-full'],
    queryFn: () => fetchClient<any>('/admin/menu'),
  })

  const { data: addonsData, isLoading: isLoadingAddons } = useQuery({
    queryKey: ['admin-menu-addons'],
    queryFn: () => fetchClient<any>('/admin/menu/addons'),
  })

  // Backend /admin/menu returns an array of categories, each with menuItems
  const categories = Array.isArray(data) ? data : []
  const items = categories.flatMap((cat: any) => 
    cat.menuItems?.map((item: any) => ({ ...item, categoryName: cat.name })) || []
  )
  const addons = Array.isArray(addonsData) ? addonsData : []
  
  const loading = isLoading || isLoadingAddons

  return (
    <motion.div 
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.4 }}
      className="space-y-6 pb-10"
    >
      {/* Header Card */}
      <div className="bg-white rounded-3xl p-6 shadow-[0_4px_25px_rgba(0,0,0,0.03)] border border-slate-50 flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h2 className="text-3xl font-black text-slate-800 tracking-tight flex items-center gap-3">
            <div className="bg-red-50 p-2 rounded-2xl">
              <MenuSquare className="h-6 w-6 text-red-500" />
            </div>
            Menu Management
          </h2>
          <p className="text-slate-500 font-medium mt-1">
            Organize your categories, items, and addons completely.
          </p>
        </div>
      </div>

      {/* Main Content Card */}
      <div className="bg-white rounded-3xl shadow-[0_4px_25px_rgba(0,0,0,0.03)] border border-slate-50 p-4 sm:p-6 min-h-[500px]">
        {loading ? (
          <div className="flex flex-col items-center justify-center h-[400px] gap-4 text-slate-500">
            <div className="relative flex items-center justify-center">
              <div className="absolute inset-0 bg-red-500 opacity-20 blur-xl rounded-full" />
              <div className="h-10 w-10 animate-spin rounded-full border-4 border-red-500/30 border-t-red-500 z-10" />
            </div>
            <p className="font-medium animate-pulse text-red-400">Loading comprehensive menu...</p>
          </div>
        ) : (
          <Tabs defaultValue="items" className="w-full">
            <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center mb-6 gap-4">
              <TabsList className="bg-slate-50 border border-slate-100 p-1.5 rounded-full shadow-inner">
                <TabsTrigger value="categories" className="rounded-full data-[state=active]:bg-white data-[state=active]:text-red-500 data-[state=active]:shadow-sm px-4 py-2 font-semibold text-slate-500 transition-all">
                  <Layers className="h-4 w-4 mr-2" /> Categories
                </TabsTrigger>
                <TabsTrigger value="items" className="rounded-full data-[state=active]:bg-white data-[state=active]:text-red-500 data-[state=active]:shadow-sm px-4 py-2 font-semibold text-slate-500 transition-all">
                  <Grid className="h-4 w-4 mr-2" /> Menu Items
                </TabsTrigger>
                <TabsTrigger value="addons" className="rounded-full data-[state=active]:bg-white data-[state=active]:text-red-500 data-[state=active]:shadow-sm px-4 py-2 font-semibold text-slate-500 transition-all">
                  <Boxes className="h-4 w-4 mr-2" /> Addons
                </TabsTrigger>
              </TabsList>
            </div>

            {/* CATEGORIES TAB */}
            <TabsContent value="categories" className="space-y-4 outline-none">
              <div className="flex justify-end mb-4">
                <Dialog>
                  <DialogTrigger>
                    <Button className="bg-gradient-to-r from-red-400 to-rose-400 text-white rounded-full font-bold shadow-md shadow-red-500/20 hover:shadow-red-500/40 transition-all border-0 h-10 px-6">
                      <Plus className="mr-2 h-4 w-4" /> Add Category
                    </Button>
                  </DialogTrigger>
                  <DialogContent className="sm:max-w-[425px] bg-white border border-slate-100 shadow-2xl rounded-3xl overflow-hidden">
                    <DialogHeader className="bg-slate-50/50 -mx-6 -mt-6 p-6 border-b border-slate-100">
                      <DialogTitle className="text-xl font-bold text-slate-800">Add Category</DialogTitle>
                      <DialogDescription className="text-slate-500">Create a new category grouping.</DialogDescription>
                    </DialogHeader>
                    <div className="pt-4">
                      <CategoryForm />
                    </div>
                  </DialogContent>
                </Dialog>
              </div>
              <div className="border border-slate-100 rounded-2xl overflow-hidden">
                <DataTable columns={categoryColumns} data={categories} />
              </div>
            </TabsContent>

            {/* ITEMS TAB */}
            <TabsContent value="items" className="space-y-4 outline-none">
              <div className="flex justify-end mb-4">
                <Sheet>
                  <SheetTrigger>
                    <Button className="bg-gradient-to-r from-red-400 to-rose-400 text-white rounded-full font-bold shadow-md shadow-red-500/20 hover:shadow-red-500/40 transition-all border-0 h-10 px-6">
                      <Plus className="mr-2 h-4 w-4" /> Add Item
                    </Button>
                  </SheetTrigger>
                  <SheetContent className="sm:max-w-[600px] w-[90vw] bg-slate-50 border-l border-slate-200 p-0 overflow-hidden flex flex-col shadow-2xl">
                    <div className="p-6 border-b border-slate-200 bg-white">
                      <SheetHeader>
                        <SheetTitle className="text-2xl font-black text-slate-800">Add Menu Item</SheetTitle>
                        <SheetDescription className="text-slate-500">Create a new food item and assign it to a category.</SheetDescription>
                      </SheetHeader>
                    </div>
                    <div className="flex-1 overflow-y-auto p-6 custom-scrollbar bg-slate-50">
                      <ItemForm categories={categories} />
                    </div>
                  </SheetContent>
                </Sheet>
              </div>
              <div className="border border-slate-100 rounded-2xl overflow-hidden">
                <DataTable columns={itemColumns} data={items} />
              </div>
            </TabsContent>

            {/* ADDONS TAB */}
            <TabsContent value="addons" className="space-y-4 outline-none">
              <div className="flex justify-end mb-4">
                <Dialog>
                  <DialogTrigger>
                    <Button className="bg-gradient-to-r from-red-400 to-rose-400 text-white rounded-full font-bold shadow-md shadow-red-500/20 hover:shadow-red-500/40 transition-all border-0 h-10 px-6">
                      <Plus className="mr-2 h-4 w-4" /> Add Addon
                    </Button>
                  </DialogTrigger>
                  <DialogContent className="sm:max-w-[425px] bg-white border border-slate-100 shadow-2xl rounded-3xl overflow-hidden">
                    <DialogHeader className="bg-slate-50/50 -mx-6 -mt-6 p-6 border-b border-slate-100">
                      <DialogTitle className="text-xl font-bold text-slate-800">Add Addon</DialogTitle>
                      <DialogDescription className="text-slate-500">Create a modifier or extra that customers can add to items.</DialogDescription>
                    </DialogHeader>
                    <div className="pt-4">
                      <AddonForm />
                    </div>
                  </DialogContent>
                </Dialog>
              </div>
              <div className="border border-slate-100 rounded-2xl overflow-hidden">
                <DataTable columns={addonColumns} data={addons} />
              </div>
            </TabsContent>

          </Tabs>
        )}
      </div>
    </motion.div>
  )
}
