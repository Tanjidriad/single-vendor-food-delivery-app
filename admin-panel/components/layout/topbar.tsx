"use client";

import { Menu } from "lucide-react";

import { Button } from "@/components/ui/button";
import { BranchSwitcher } from "@/components/layout/branch-switcher";
import { ThemeToggle } from "@/components/layout/theme-toggle";
import { UserMenu } from "@/components/layout/user-menu";

export function Topbar({ onMenuClick }: { onMenuClick: () => void }) {
  return (
    <header className="bg-background/80 sticky top-0 z-30 flex h-16 items-center gap-3 border-b px-4 backdrop-blur-md lg:px-6">
      <Button
        variant="ghost"
        size="icon-sm"
        className="lg:hidden"
        aria-label="Open navigation"
        onClick={onMenuClick}
      >
        <Menu className="size-5" />
      </Button>

      <BranchSwitcher />

      <div className="ml-auto flex items-center gap-1.5">
        <ThemeToggle />
        <div className="bg-border mx-1 h-6 w-px" />
        <UserMenu />
      </div>
    </header>
  );
}
