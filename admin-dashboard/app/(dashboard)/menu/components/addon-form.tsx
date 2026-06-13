import { Label } from "@/components/ui/label"
import { Input } from "@/components/ui/input"
import { Button } from "@/components/ui/button"

export function AddonForm() {
  return (
    <form className="grid gap-4 py-4" onSubmit={(e) => e.preventDefault()}>
      <div className="grid gap-2">
        <Label htmlFor="addon-name" className="text-slate-700 font-bold">Addon Name</Label>
        <Input id="addon-name" placeholder="e.g. Extra Cheese" className="bg-slate-50 border-slate-200 text-slate-800 focus-visible:ring-red-200 shadow-inner" />
      </div>
      <div className="grid gap-2">
        <Label htmlFor="addon-price" className="text-slate-700 font-bold">Price (৳)</Label>
        <Input id="addon-price" type="number" placeholder="0.00" className="bg-slate-50 border-slate-200 text-slate-800 focus-visible:ring-red-200 shadow-inner" />
      </div>
      <div className="flex items-center space-x-2 mt-2">
        <input type="checkbox" id="addon-active" defaultChecked className="h-4 w-4 rounded border-slate-300 text-red-500 focus:ring-red-500 focus:ring-offset-white cursor-pointer" />
        <Label htmlFor="addon-active" className="text-slate-600 font-medium cursor-pointer">Is Active?</Label>
      </div>
      <Button type="submit" className="w-full bg-gradient-to-r from-red-400 to-rose-400 text-white shadow-md shadow-red-500/20 hover:shadow-red-500/40 rounded-full font-bold mt-4 transition-all">
        Save Addon
      </Button>
    </form>
  )
}
