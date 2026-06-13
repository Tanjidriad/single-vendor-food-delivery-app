"use client"

import { AppSidebar } from "@/components/layout/app-sidebar"
import { Header } from "@/components/layout/header"
import { RightPanel } from "@/components/layout/right-panel"
import { useAuthStore } from "@/store/auth-store"
import { useRouter } from "next/navigation"
import { useEffect } from "react"

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode
}) {
  const { isAuthenticated } = useAuthStore()
  const router = useRouter()

  useEffect(() => {
    if (!isAuthenticated) {
      router.push("/login")
    }
  }, [isAuthenticated, router])

  if (!isAuthenticated) {
    return null // prevent flash of protected content
  }

  return (
    <div className="flex min-h-screen w-full bg-[#FAFBFC] text-slate-800 relative font-sans overflow-hidden">
      {/* 1. Left Sidebar (Slim) */}
      <AppSidebar />
      
      {/* 2. Main Content Area */}
      <div className="flex flex-1 flex-col w-full min-w-0 transition-all duration-300 ease-in-out z-10 h-screen overflow-hidden">
        {/* Top Header */}
        <Header />
        
        {/* Scrollable Main Area */}
        <main className="flex-1 overflow-x-hidden overflow-y-auto bg-transparent p-8">
          <div className="mx-auto max-w-[1400px] w-full">
            {children}
          </div>
        </main>
      </div>

      {/* 3. Right Permanent Panel */}
      <RightPanel />
    </div>
  )
}
