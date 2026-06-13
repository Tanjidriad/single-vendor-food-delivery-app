"use client"

import { Settings as SettingsIcon, Save } from "lucide-react"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Separator } from "@/components/ui/separator"
import { motion } from "framer-motion"

export default function SettingsPage() {
  return (
    <motion.div 
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.4 }}
      className="space-y-6 max-w-4xl mx-auto"
    >
      <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between bg-white p-6 rounded-3xl shadow-[0_4px_25px_rgba(0,0,0,0.03)] border border-slate-50">
        <div>
          <h2 className="text-3xl font-bold tracking-tight flex items-center gap-2">
            <SettingsIcon className="h-8 w-8 text-primary" />
            Platform Settings
          </h2>
          <p className="text-slate-500 font-medium mt-1">
            Global configuration for the entire delivery network.
          </p>
        </div>
        <Button className="bg-gradient-to-r from-red-400 to-rose-400 text-white rounded-full font-bold shadow-md shadow-red-500/20 hover:shadow-red-500/40 transition-all border-0 h-10 px-6">
          <Save className="mr-2 h-4 w-4" />
          Save Changes
        </Button>
      </div>

      <div className="grid gap-6">
        <Card className="bg-white border-slate-100 shadow-sm hover:shadow-md hover:border-slate-200 transition-all">
          <CardHeader>
            <CardTitle>Delivery Fees</CardTitle>
            <CardDescription>Configure global base rules for delivery pricing.</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>Default Base Fee (৳)</Label>
                <Input defaultValue="30" className="bg-background/50 border-white/10 hover:border-white/20 transition-colors" />
              </div>
              <div className="space-y-2">
                <Label>Default Per KM Fee (৳)</Label>
                <Input defaultValue="10" className="bg-background/50 border-white/10 hover:border-white/20 transition-colors" />
              </div>
            </div>
            <div className="space-y-2">
              <Label>Maximum Delivery Radius (km)</Label>
              <Input defaultValue="15" className="bg-background/50 border-white/10 hover:border-white/20 transition-colors" />
            </div>
          </CardContent>
        </Card>

        <Card className="bg-white border-slate-100 shadow-sm hover:shadow-md hover:border-slate-200 transition-all">
          <CardHeader>
            <CardTitle>Commissions & Taxes</CardTitle>
            <CardDescription>Set the platform cuts and default tax rates.</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>Platform Commission (%)</Label>
                <Input defaultValue="15" className="bg-background/50 border-white/10 hover:border-white/20 transition-colors" />
              </div>
              <div className="space-y-2">
                <Label>Default Tax/VAT Rate (%)</Label>
                <Input defaultValue="5" className="bg-background/50 border-white/10 hover:border-white/20 transition-colors" />
              </div>
            </div>
          </CardContent>
        </Card>

        <Card className="bg-white border-slate-100 shadow-sm hover:shadow-md hover:border-slate-200 transition-all">
          <CardHeader>
            <CardTitle>Service Level Agreements (SLAs)</CardTitle>
            <CardDescription>Default timeout thresholds for the system.</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>Kitchen Auto-Reject Timeout (mins)</Label>
                <Input defaultValue="10" className="bg-background/50 border-white/10 hover:border-white/20 transition-colors" />
              </div>
              <div className="space-y-2">
                <Label>Rider Assignment Timeout (secs)</Label>
                <Input defaultValue="45" className="bg-background/50 border-white/10 hover:border-white/20 transition-colors" />
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
    </motion.div>
  )
}
