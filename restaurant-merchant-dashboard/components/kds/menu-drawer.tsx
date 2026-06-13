"use client";

import { X } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Switch } from "@/components/ui/switch";
import { cn } from "@/lib/utils";

export interface MenuItem {
  id: string;
  name: string;
  category: string;
  isAvailable: boolean;
}

interface MenuDrawerProps {
  isOpen: boolean;
  onClose: () => void;
  items: MenuItem[];
  onToggleAvailability: (itemId: string) => void;
}

export function MenuDrawer({
  isOpen,
  onClose,
  items,
  onToggleAvailability,
}: MenuDrawerProps) {
  const categories = [...new Set(items.map((item) => item.category))];
  const unavailableCount = items.filter((item) => !item.isAvailable).length;

  return (
    <>
      {/* Backdrop */}
      {isOpen && (
        <div
          className="fixed inset-0 bg-black/50 z-40"
          onClick={onClose}
        />
      )}

      {/* Drawer */}
      <div
        className={cn(
          "fixed top-0 right-0 h-full w-full md:w-96 bg-card border-l border-border z-50 transform transition-transform duration-300 ease-in-out flex flex-col",
          isOpen ? "translate-x-0" : "translate-x-full"
        )}
      >
        {/* Drawer Header */}
        <div className="px-4 md:px-6 py-4 md:py-5 border-b border-border flex items-center justify-between">
          <div>
            <h2 className="text-lg md:text-xl font-bold text-foreground">Menu Availability</h2>
            <p className="text-xs md:text-sm text-muted-foreground mt-1">
              86 List • {unavailableCount} item{unavailableCount !== 1 ? "s" : ""} unavailable
            </p>
          </div>
          <Button
            variant="ghost"
            size="icon"
            onClick={onClose}
            className="hover:bg-secondary"
          >
            <X className="w-5 h-5" />
          </Button>
        </div>

        {/* Drawer Content */}
        <div className="flex-1 overflow-y-auto p-4 md:p-6 space-y-5 md:space-y-6 pb-20 md:pb-6">
          {categories.map((category) => (
            <div key={category}>
              <h3 className="text-xs md:text-sm font-semibold text-muted-foreground uppercase tracking-wider mb-2 md:mb-3">
                {category}
              </h3>
              <div className="space-y-2">
                {items
                  .filter((item) => item.category === category)
                  .map((item) => (
                    <div
                      key={item.id}
                      className={cn(
                        "flex items-center justify-between p-2.5 md:p-3 rounded-lg border transition-colors",
                        item.isAvailable
                          ? "border-border bg-secondary/30"
                          : "border-kds-urgent/30 bg-kds-urgent/10"
                      )}
                    >
                      <span
                        className={cn(
                          "font-medium text-sm md:text-base",
                          item.isAvailable ? "text-foreground" : "text-kds-urgent"
                        )}
                      >
                        {item.name}
                      </span>
                      <div className="flex items-center gap-2 md:gap-3">
                        <span
                          className={cn(
                            "text-[10px] md:text-xs font-medium hidden sm:inline",
                            item.isAvailable
                              ? "text-kds-success"
                              : "text-kds-urgent"
                          )}
                        >
                          {item.isAvailable ? "In Stock" : "Out"}
                        </span>
                        <Switch
                          checked={item.isAvailable}
                          onCheckedChange={() => onToggleAvailability(item.id)}
                          className="data-[state=checked]:bg-kds-success"
                        />
                      </div>
                    </div>
                  ))}
              </div>
            </div>
          ))}
        </div>
      </div>
    </>
  );
}
