"use client";

import { useState, useEffect } from "react";
import { ChevronDown, Pause, Play, Menu } from "lucide-react";
import { Button } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { cn } from "@/lib/utils";

interface HeaderProps {
  restaurantName: string;
  isOnline: boolean;
  isBusyMode: boolean;
  onToggleBusyMode: () => void;
  onStatusChange: (status: string) => void;
  onOpenMenu?: () => void;
}

export function Header({
  restaurantName,
  isOnline,
  isBusyMode,
  onToggleBusyMode,
  onStatusChange,
  onOpenMenu,
}: HeaderProps) {
  const [currentTime, setCurrentTime] = useState<string>("");

  useEffect(() => {
    const updateTime = () => {
      const now = new Date();
      setCurrentTime(
        now.toLocaleTimeString("en-US", {
          hour: "2-digit",
          minute: "2-digit",
          hour12: true,
        })
      );
    };
    updateTime();
    const interval = setInterval(updateTime, 1000);
    return () => clearInterval(interval);
  }, []);

  return (
    <>
      {/* Desktop Header */}
      <header className="hidden md:flex h-16 bg-card border-b border-border items-center justify-between px-6">
        {/* Left: Restaurant Name & Status */}
        <div className="flex items-center gap-4">
          <h1 className="text-xl font-bold text-foreground">{restaurantName}</h1>
          <div className="flex items-center gap-2">
            <span
              className={cn(
                "w-2.5 h-2.5 rounded-full",
                isOnline ? "bg-kds-success animate-pulse" : "bg-kds-urgent"
              )}
            />
            <span
              className={cn(
                "text-sm font-medium",
                isOnline ? "text-kds-success" : "text-kds-urgent"
              )}
            >
              {isOnline ? "Online" : "Offline"}
            </span>
          </div>
        </div>

        {/* Center: Current Time */}
        <div className="absolute left-1/2 -translate-x-1/2">
          <span className="text-3xl font-bold text-foreground tracking-tight">
            {currentTime}
          </span>
        </div>

        {/* Right: Controls */}
        <div className="flex items-center gap-4">
          {/* Busy Mode Toggle */}
          <Button
            onClick={onToggleBusyMode}
            className={cn(
              "h-10 px-4 font-semibold transition-colors",
              isBusyMode
                ? "bg-kds-warning text-black hover:bg-kds-warning/90"
                : "bg-secondary text-foreground hover:bg-secondary/80"
            )}
          >
            {isBusyMode ? (
              <>
                <Play className="w-4 h-4 mr-2" />
                Resume Orders
              </>
            ) : (
              <>
                <Pause className="w-4 h-4 mr-2" />
                Busy Mode
              </>
            )}
          </Button>

          {/* Store Status Dropdown */}
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button variant="outline" className="h-10 border-border">
                Store Status
                <ChevronDown className="w-4 h-4 ml-2" />
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end" className="w-48">
              <DropdownMenuItem onClick={() => onStatusChange("open")}>
                <span className="w-2 h-2 rounded-full bg-kds-success mr-2" />
                Open for Orders
              </DropdownMenuItem>
              <DropdownMenuItem onClick={() => onStatusChange("busy")}>
                <span className="w-2 h-2 rounded-full bg-kds-warning mr-2" />
                Busy - Longer Wait
              </DropdownMenuItem>
              <DropdownMenuItem onClick={() => onStatusChange("closed")}>
                <span className="w-2 h-2 rounded-full bg-kds-urgent mr-2" />
                Temporarily Closed
              </DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>
        </div>
      </header>

      {/* Mobile Header */}
      <header className="md:hidden bg-card border-b border-border">
        {/* Top Row */}
        <div className="flex items-center justify-between px-4 h-14">
          <div className="flex items-center gap-3">
            <h1 className="text-lg font-bold text-foreground">{restaurantName}</h1>
            <div className="flex items-center gap-1.5">
              <span
                className={cn(
                  "w-2 h-2 rounded-full",
                  isOnline ? "bg-kds-success animate-pulse" : "bg-kds-urgent"
                )}
              />
              <span
                className={cn(
                  "text-xs font-medium",
                  isOnline ? "text-kds-success" : "text-kds-urgent"
                )}
              >
                {isOnline ? "Online" : "Offline"}
              </span>
            </div>
          </div>
          <span className="text-xl font-bold text-foreground tracking-tight">
            {currentTime}
          </span>
        </div>

        {/* Bottom Row - Controls */}
        <div className="flex items-center gap-2 px-4 pb-3">
          <Button
            onClick={onToggleBusyMode}
            size="sm"
            className={cn(
              "flex-1 h-9 font-semibold text-sm transition-colors",
              isBusyMode
                ? "bg-kds-warning text-black hover:bg-kds-warning/90"
                : "bg-secondary text-foreground hover:bg-secondary/80"
            )}
          >
            {isBusyMode ? (
              <>
                <Play className="w-4 h-4 mr-1.5" />
                Resume
              </>
            ) : (
              <>
                <Pause className="w-4 h-4 mr-1.5" />
                Busy Mode
              </>
            )}
          </Button>

          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button variant="outline" size="sm" className="flex-1 h-9 border-border">
                Status
                <ChevronDown className="w-4 h-4 ml-1.5" />
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end" className="w-48">
              <DropdownMenuItem onClick={() => onStatusChange("open")}>
                <span className="w-2 h-2 rounded-full bg-kds-success mr-2" />
                Open for Orders
              </DropdownMenuItem>
              <DropdownMenuItem onClick={() => onStatusChange("busy")}>
                <span className="w-2 h-2 rounded-full bg-kds-warning mr-2" />
                Busy - Longer Wait
              </DropdownMenuItem>
              <DropdownMenuItem onClick={() => onStatusChange("closed")}>
                <span className="w-2 h-2 rounded-full bg-kds-urgent mr-2" />
                Temporarily Closed
              </DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>

          <Button
            variant="outline"
            size="sm"
            className="h-9 w-9 p-0 border-border"
            onClick={onOpenMenu}
          >
            <Menu className="w-4 h-4" />
          </Button>
        </div>
      </header>
    </>
  );
}
