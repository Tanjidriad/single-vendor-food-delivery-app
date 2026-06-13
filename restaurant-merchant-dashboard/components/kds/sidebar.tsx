"use client";

import { 
  LayoutGrid, 
  History, 
  UtensilsCrossed, 
  BarChart3, 
  Settings,
  ChefHat
} from "lucide-react";
import { cn } from "@/lib/utils";

const navItems = [
  { icon: LayoutGrid, label: "Orders" },
  { icon: History, label: "History" },
  { icon: UtensilsCrossed, label: "86 List" },
  { icon: BarChart3, label: "Analytics" },
  { icon: Settings, label: "Settings" },
];

interface SidebarProps {
  activeIndex: number;
  onNavigate: (index: number) => void;
}

export function Sidebar({ activeIndex, onNavigate }: SidebarProps) {
  return (
    <>
      {/* Desktop Sidebar */}
      <aside className="hidden md:flex w-20 bg-sidebar border-r border-sidebar-border flex-col items-center py-6">
        {/* Logo */}
        <div className="w-12 h-12 rounded-xl bg-kds-success/20 flex items-center justify-center mb-8">
          <ChefHat className="w-7 h-7 text-kds-success" />
        </div>

        {/* Navigation */}
        <nav className="flex-1 flex flex-col gap-2">
          {navItems.map((item, idx) => {
            const Icon = item.icon;
            const isActive = idx === activeIndex;
            return (
              <button
                key={idx}
                onClick={() => onNavigate(idx)}
                className={cn(
                  "w-14 h-14 rounded-xl flex items-center justify-center transition-all",
                  isActive
                    ? "bg-sidebar-accent text-sidebar-primary"
                    : "text-muted-foreground hover:bg-sidebar-accent/50 hover:text-foreground"
                )}
                title={item.label}
              >
                <Icon className="w-6 h-6" />
              </button>
            );
          })}
        </nav>
      </aside>

      {/* Mobile Bottom Navigation */}
      <nav className="md:hidden fixed bottom-0 left-0 right-0 z-50 bg-sidebar border-t border-sidebar-border safe-area-pb">
        <div className="flex items-center justify-around h-16">
          {navItems.map((item, idx) => {
            const Icon = item.icon;
            const isActive = idx === activeIndex;
            return (
              <button
                key={idx}
                onClick={() => onNavigate(idx)}
                className={cn(
                  "flex flex-col items-center justify-center gap-1 px-3 py-2 rounded-lg transition-all min-w-[4rem]",
                  isActive
                    ? "text-sidebar-primary"
                    : "text-muted-foreground active:text-foreground"
                )}
              >
                <Icon className={cn("w-5 h-5", isActive && "text-kds-success")} />
                <span className="text-[10px] font-medium">{item.label}</span>
              </button>
            );
          })}
        </div>
      </nav>
    </>
  );
}
