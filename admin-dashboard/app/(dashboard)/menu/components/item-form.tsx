import { Label } from "@/components/ui/label"
import { Input } from "@/components/ui/input"
import { Button } from "@/components/ui/button"
import { Info, DollarSign, Eye, Tag, ListOrdered, Image as ImageIcon } from "lucide-react"

export function ItemForm({ categories }: { categories: any[] }) {
  return (
    <form className="space-y-8 pb-10" onSubmit={(e) => e.preventDefault()}>
      
      {/* Basic Info Section */}
      <div className="space-y-5">
        <div className="flex items-center gap-3 border-b border-slate-100 pb-2">
          <div className="p-1.5 bg-red-50 rounded-lg">
            <Info className="h-4 w-4 text-red-500" />
          </div>
          <h4 className="font-bold text-base text-slate-800 tracking-tight">Basic Information</h4>
        </div>
        
        <div className="grid gap-5">
          <div className="grid gap-2">
            <Label htmlFor="item-name" className="text-sm font-bold text-slate-700">Item Name <span className="text-red-500">*</span></Label>
            <Input id="item-name" placeholder="e.g. Signature Truffle Burger" className="bg-white border-slate-200 focus-visible:ring-red-200 h-11 text-base shadow-[0_2px_10px_rgba(0,0,0,0.02)]" />
          </div>
          
          <div className="grid gap-2">
            <Label htmlFor="item-cat" className="text-sm font-bold text-slate-700">Category <span className="text-red-500">*</span></Label>
            <div className="relative">
              <select id="item-cat" className="appearance-none flex h-11 w-full rounded-md border border-slate-200 bg-white px-3 py-2 text-base text-slate-800 shadow-[0_2px_10px_rgba(0,0,0,0.02)] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-red-200 cursor-pointer">
                <option value="" disabled selected>Select category...</option>
                {categories?.map((c) => (
                  <option key={c.id} value={c.id}>{c.name}</option>
                ))}
              </select>
              <div className="pointer-events-none absolute inset-y-0 right-0 flex items-center px-3 text-slate-400">
                <ListOrdered className="h-4 w-4" />
              </div>
            </div>
          </div>

          <div className="grid gap-2">
            <Label htmlFor="item-desc" className="text-sm font-bold text-slate-700">Description</Label>
            <textarea 
              id="item-desc" 
              placeholder="Describe the ingredients and preparation..." 
              className="flex min-h-[100px] w-full rounded-md border border-slate-200 bg-white px-3 py-3 text-base text-slate-800 shadow-[0_2px_10px_rgba(0,0,0,0.02)] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-red-200 resize-y" 
            />
          </div>

          <div className="grid gap-2">
            <Label htmlFor="item-image" className="text-sm font-bold text-slate-700">Image URL</Label>
            <div className="relative">
              <ImageIcon className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-400" />
              <Input id="item-image" placeholder="https://..." className="bg-white border-slate-200 focus-visible:ring-red-200 h-11 pl-10 text-base shadow-[0_2px_10px_rgba(0,0,0,0.02)]" />
            </div>
          </div>
        </div>
      </div>

      {/* Pricing Section */}
      <div className="space-y-5">
        <div className="flex items-center gap-3 border-b border-slate-100 pb-2">
          <div className="p-1.5 bg-emerald-50 rounded-lg">
            <DollarSign className="h-4 w-4 text-emerald-500" />
          </div>
          <h4 className="font-bold text-base text-slate-800 tracking-tight">Pricing Strategy</h4>
        </div>
        
        <div className="grid grid-cols-2 gap-5">
          <div className="grid gap-2">
            <Label htmlFor="item-price" className="text-sm font-bold text-slate-700">Selling Price (৳) <span className="text-red-500">*</span></Label>
            <Input id="item-price" type="number" placeholder="0.00" className="bg-white border-slate-200 focus-visible:ring-red-200 h-11 text-base font-medium tabular-nums shadow-[0_2px_10px_rgba(0,0,0,0.02)]" />
          </div>
          <div className="grid gap-2">
            <Label htmlFor="item-compare" className="text-sm font-bold text-slate-700">Compare-at Price (৳)</Label>
            <Input id="item-compare" type="number" placeholder="Optional" className="bg-white border-slate-200 focus-visible:ring-red-200 h-11 text-base tabular-nums shadow-[0_2px_10px_rgba(0,0,0,0.02)]" />
            <p className="text-[11px] text-slate-400 mt-1">Shows a strike-through original price.</p>
          </div>
        </div>
      </div>

      {/* Visibility Section */}
      <div className="space-y-5">
        <div className="flex items-center gap-3 border-b border-slate-100 pb-2">
          <div className="p-1.5 bg-violet-50 rounded-lg">
            <Eye className="h-4 w-4 text-violet-500" />
          </div>
          <h4 className="font-bold text-base text-slate-800 tracking-tight">Status & Visibility</h4>
        </div>
        
        <div className="grid gap-5">
          <div className="grid gap-2">
            <Label htmlFor="item-tags" className="text-sm font-bold text-slate-700">Tags (Comma Separated)</Label>
            <div className="relative">
              <Tag className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-400" />
              <Input id="item-tags" placeholder="e.g. bestseller, spicy, vegan" className="bg-white border-slate-200 focus-visible:ring-red-200 h-11 pl-10 text-base shadow-[0_2px_10px_rgba(0,0,0,0.02)]" />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-5">
            <div className="grid gap-2">
              <Label htmlFor="item-sort" className="text-sm font-bold text-slate-700">Sort Priority</Label>
              <Input id="item-sort" type="number" defaultValue="0" className="bg-white border-slate-200 focus-visible:ring-red-200 h-11 text-base shadow-[0_2px_10px_rgba(0,0,0,0.02)]" />
            </div>
          </div>

          <div className="flex flex-col sm:flex-row gap-6 mt-4 p-5 rounded-xl border border-slate-100 bg-white shadow-[0_4px_20px_rgba(0,0,0,0.02)]">
            <label className="flex items-center gap-4 cursor-pointer group">
              <div className="relative">
                <input type="checkbox" id="item-avail" className="peer sr-only" defaultChecked />
                <div className="block h-7 w-12 rounded-full bg-slate-200 border border-slate-300 peer-checked:bg-red-500 peer-checked:border-red-500 transition-all duration-300"></div>
                <div className="absolute left-1 top-1 h-5 w-5 rounded-full bg-white shadow-sm transition-transform duration-300 peer-checked:translate-x-5"></div>
              </div>
              <div className="flex flex-col">
                <span className="text-sm font-bold text-slate-800 group-hover:text-red-500 transition-colors">Available</span>
                <span className="text-xs text-slate-500">Customers can order this</span>
              </div>
            </label>

            <div className="hidden sm:block w-px bg-slate-100 h-10"></div>

            <label className="flex items-center gap-4 cursor-pointer group">
              <div className="relative">
                <input type="checkbox" id="item-feat" className="peer sr-only" />
                <div className="block h-7 w-12 rounded-full bg-slate-200 border border-slate-300 peer-checked:bg-amber-400 peer-checked:border-amber-400 transition-all duration-300"></div>
                <div className="absolute left-1 top-1 h-5 w-5 rounded-full bg-white shadow-sm transition-transform duration-300 peer-checked:translate-x-5"></div>
              </div>
              <div className="flex flex-col">
                <span className="text-sm font-bold text-slate-800 group-hover:text-amber-500 transition-colors">Featured</span>
                <span className="text-xs text-slate-500">Show in prominent areas</span>
              </div>
            </label>
          </div>
        </div>
      </div>

      <div className="pt-6 sticky bottom-0 bg-white/90 backdrop-blur-md py-4 border-t border-slate-100 -mx-1 px-1 z-10">
        <Button type="submit" className="w-full h-12 text-base font-bold text-white bg-gradient-to-r from-red-400 to-rose-400 shadow-lg shadow-red-500/20 hover:shadow-red-500/40 rounded-full transition-all duration-300 hover:-translate-y-0.5">
          Save Menu Item
        </Button>
      </div>
    </form>
  )
}
