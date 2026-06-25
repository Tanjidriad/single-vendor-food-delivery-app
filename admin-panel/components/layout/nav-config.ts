import {
  LayoutDashboard,
  ShoppingBag,
  Radio,
  UtensilsCrossed,
  Users,
  Bike,
  Megaphone,
  Wallet,
  Settings,
  type LucideIcon,
} from "lucide-react";

import type { UserRole } from "@/types";

export interface NavItem {
  label: string;
  href: string;
  icon: LucideIcon;
  /** Roles allowed to see this item. Omit = all staff. */
  roles?: UserRole[];
}

export interface NavSection {
  heading?: string;
  items: NavItem[];
}

// Data-driven nav. Super-admin (ADMIN-only platform) entries are added here
// later with `roles: ["ADMIN"]` — no structural change required.
export const navSections: NavSection[] = [
  {
    items: [{ label: "Dashboard", href: "/", icon: LayoutDashboard }],
  },
  {
    heading: "Operations",
    items: [
      { label: "Orders", href: "/orders", icon: ShoppingBag },
      { label: "Live Operations", href: "/operations", icon: Radio },
    ],
  },
  {
    heading: "Catalog",
    items: [{ label: "Menu", href: "/menu", icon: UtensilsCrossed }],
  },
  {
    heading: "People",
    items: [
      { label: "Customers", href: "/customers", icon: Users },
      { label: "Riders", href: "/riders", icon: Bike },
    ],
  },
  {
    heading: "Growth",
    items: [{ label: "Promotions", href: "/promotions", icon: Megaphone }],
  },
  {
    heading: "Business",
    items: [
      {
        label: "Finance",
        href: "/finance",
        icon: Wallet,
        roles: ["OWNER", "MANAGER", "ADMIN"],
      },
      {
        label: "Settings",
        href: "/settings",
        icon: Settings,
        roles: ["OWNER", "MANAGER", "ADMIN"],
      },
    ],
  },
];
