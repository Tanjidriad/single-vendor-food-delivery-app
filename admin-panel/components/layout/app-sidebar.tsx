"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { UtensilsCrossed } from "lucide-react";

import { navSections } from "@/components/layout/nav-config";
import { useAuth } from "@/lib/auth/use-auth";
import { hasRole } from "@/lib/auth/roles";
import { cn } from "@/lib/utils";

function isActive(pathname: string, href: string) {
  if (href === "/") return pathname === "/";
  return pathname === href || pathname.startsWith(`${href}/`);
}

export function AppSidebar({ onNavigate }: { onNavigate?: () => void }) {
  const pathname = usePathname();
  const { role } = useAuth();

  return (
    <div className="bg-sidebar text-sidebar-foreground flex h-full w-64 flex-col border-r">
      {/* Brand */}
      <div className="flex h-16 items-center gap-2.5 px-5">
        <div className="bg-primary text-primary-foreground flex size-9 items-center justify-center rounded-lg shadow-sm">
          <UtensilsCrossed className="size-5" />
        </div>
        <div className="leading-tight">
          <p className="text-sm font-semibold">Food Admin</p>
          <p className="text-muted-foreground text-xs">Operations Console</p>
        </div>
      </div>

      {/* Nav */}
      <nav className="scrollbar-thin flex-1 space-y-5 overflow-y-auto px-3 py-3">
        {navSections.map((section, i) => {
          const items = section.items.filter(
            (item) => !item.roles || hasRole(role, item.roles)
          );
          if (items.length === 0) return null;
          return (
            <div key={section.heading ?? i}>
              {section.heading && (
                <p className="text-muted-foreground/70 px-3 pb-1.5 text-[0.7rem] font-semibold uppercase tracking-wider">
                  {section.heading}
                </p>
              )}
              <ul className="space-y-0.5">
                {items.map((item) => {
                  const active = isActive(pathname, item.href);
                  return (
                    <li key={item.href}>
                      <Link
                        href={item.href}
                        onClick={onNavigate}
                        aria-current={active ? "page" : undefined}
                        className={cn(
                          "group flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium transition-colors",
                          active
                            ? "bg-sidebar-primary text-sidebar-primary-foreground shadow-sm"
                            : "text-sidebar-foreground/80 hover:bg-sidebar-accent hover:text-sidebar-accent-foreground"
                        )}
                      >
                        <item.icon
                          className={cn(
                            "size-4.5 shrink-0",
                            active
                              ? "text-sidebar-primary-foreground"
                              : "text-muted-foreground group-hover:text-sidebar-accent-foreground"
                          )}
                        />
                        {item.label}
                      </Link>
                    </li>
                  );
                })}
              </ul>
            </div>
          );
        })}
      </nav>

      <div className="border-t px-5 py-3">
        <p className="text-muted-foreground text-xs">v1.0 · Single restaurant</p>
      </div>
    </div>
  );
}
