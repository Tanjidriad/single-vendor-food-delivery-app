import { create } from "zustand";
import { persist } from "zustand/middleware";

import type { CartLine, MenuAddon, MenuItem } from "@/types";

function lineKey(itemId: string, addons: MenuAddon[]): string {
  return `${itemId}::${addons.map((a) => a.id).sort().join(",")}`;
}

export function lineTotal(line: CartLine): number {
  const addons = line.addons.reduce((s, a) => s + a.price, 0);
  return (line.price + addons) * line.quantity;
}

interface CartState {
  lines: CartLine[];
  add: (item: MenuItem, addons: MenuAddon[], quantity: number) => void;
  setQuantity: (key: string, quantity: number) => void;
  remove: (key: string) => void;
  clear: () => void;
  subtotal: () => number;
  count: () => number;
  keyOf: (line: CartLine) => string;
}

export const useCartStore = create<CartState>()(
  persist(
    (set, get) => ({
      lines: [],
      keyOf: (line) => lineKey(line.itemId, line.addons),
      add: (item, addons, quantity) =>
        set((state) => {
          const key = lineKey(item.id, addons);
          const existing = state.lines.find(
            (l) => lineKey(l.itemId, l.addons) === key
          );
          if (existing) {
            return {
              lines: state.lines.map((l) =>
                lineKey(l.itemId, l.addons) === key
                  ? { ...l, quantity: l.quantity + quantity }
                  : l
              ),
            };
          }
          return {
            lines: [
              ...state.lines,
              {
                itemId: item.id,
                name: item.name,
                price: item.price,
                quantity,
                imageUrl: item.imageUrl,
                addons,
              },
            ],
          };
        }),
      setQuantity: (key, quantity) =>
        set((state) => ({
          lines:
            quantity <= 0
              ? state.lines.filter((l) => lineKey(l.itemId, l.addons) !== key)
              : state.lines.map((l) =>
                  lineKey(l.itemId, l.addons) === key ? { ...l, quantity } : l
                ),
        })),
      remove: (key) =>
        set((state) => ({
          lines: state.lines.filter((l) => lineKey(l.itemId, l.addons) !== key),
        })),
      clear: () => set({ lines: [] }),
      subtotal: () => get().lines.reduce((s, l) => s + lineTotal(l), 0),
      count: () => get().lines.reduce((s, l) => s + l.quantity, 0),
    }),
    { name: "customer-cart" }
  )
);
