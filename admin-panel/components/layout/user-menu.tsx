"use client";

import { LogOut, UserCircle } from "lucide-react";

import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { useAuth, useLogout } from "@/lib/auth/use-auth";
import { ROLE_LABELS } from "@/lib/auth/roles";
import { getInitials } from "@/lib/utils";

export function UserMenu() {
  const { user } = useAuth();
  const logout = useLogout();

  const name =
    user?.fullName || user?.email?.split("@")[0] || user?.phone || "Staff";

  return (
    <DropdownMenu>
      <DropdownMenuTrigger className="flex items-center gap-2 rounded-full outline-none focus-visible:ring-[3px] focus-visible:ring-ring/50">
        <Avatar className="size-8">
          <AvatarFallback className="bg-primary/10 text-primary font-semibold">
            {getInitials(name)}
          </AvatarFallback>
        </Avatar>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end" className="w-56">
        <DropdownMenuLabel className="flex flex-col gap-0.5">
          <span className="truncate font-medium">{name}</span>
          <span className="text-muted-foreground text-xs font-normal">
            {user?.email || user?.phone}
          </span>
          {user?.role && (
            <span className="text-primary mt-0.5 text-xs font-medium">
              {ROLE_LABELS[user.role]}
            </span>
          )}
        </DropdownMenuLabel>
        <DropdownMenuSeparator />
        <DropdownMenuItem disabled>
          <UserCircle className="size-4" />
          Profile
        </DropdownMenuItem>
        <DropdownMenuSeparator />
        <DropdownMenuItem variant="destructive" onClick={logout}>
          <LogOut className="size-4" />
          Sign out
        </DropdownMenuItem>
      </DropdownMenuContent>
    </DropdownMenu>
  );
}
