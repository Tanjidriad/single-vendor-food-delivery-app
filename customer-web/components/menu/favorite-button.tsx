"use client";

import { useState } from "react";
import { AnimatePresence, motion } from "framer-motion";
import { Heart } from "lucide-react";
import { toast } from "sonner";

import { useAuth } from "@/lib/auth/use-auth";
import {
  useAddFavorite,
  useFavoriteIds,
  useRemoveFavorite,
} from "@/lib/api/queries/favorites";
import { ApiError } from "@/lib/api/client";
import { cn } from "@/lib/utils";

/**
 * Reusable heart toggle. Optimistic pop animation on tap; a burst of petals
 * radiates out when a dish is newly saved. Sits on menu cards and the item sheet.
 */
export function FavoriteButton({
  menuItemId,
  itemName,
  variant = "overlay",
  className,
}: {
  menuItemId: string;
  itemName?: string;
  variant?: "overlay" | "plain";
  className?: string;
}) {
  const { isAuthenticated } = useAuth();
  const favoriteIds = useFavoriteIds();
  const add = useAddFavorite();
  const remove = useRemoveFavorite();
  const [burst, setBurst] = useState(0);

  const active = favoriteIds.has(menuItemId);
  const pending = add.isPending || remove.isPending;

  function toggle(e: React.MouseEvent) {
    e.preventDefault();
    e.stopPropagation();
    if (!isAuthenticated) {
      toast.error("Sign in to save favourites.");
      return;
    }
    if (active) {
      remove.mutate(menuItemId, {
        onError: (err) =>
          toast.error(
            err instanceof ApiError ? err.message : "Couldn't update favourites."
          ),
      });
    } else {
      setBurst((b) => b + 1);
      add.mutate(menuItemId, {
        onSuccess: () => toast.success(`${itemName ?? "Dish"} saved`),
        onError: (err) =>
          toast.error(
            err instanceof ApiError ? err.message : "Couldn't update favourites."
          ),
      });
    }
  }

  return (
    <button
      type="button"
      onClick={toggle}
      disabled={pending}
      aria-pressed={active}
      aria-label={active ? "Remove from favourites" : "Save to favourites"}
      className={cn(
        "relative grid place-items-center transition-transform focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-[color-mix(in_srgb,var(--brand)_28%,transparent)] active:scale-90",
        variant === "overlay"
          ? "h-10 w-10 rounded-full bg-black/45 text-white backdrop-blur-md"
          : "h-11 w-11 rounded-full border border-[var(--border)] bg-[var(--surface)] text-[var(--foreground-dim)] hover:border-[var(--foreground-mute)]",
        className
      )}
    >
      {/* Petal burst on save */}
      <AnimatePresence>
        {burst > 0 && active && (
          <motion.span
            key={burst}
            className="pointer-events-none absolute inset-0"
            initial={{ opacity: 1 }}
            animate={{ opacity: 0 }}
            transition={{ duration: 0.5 }}
          >
            {[0, 60, 120, 180, 240, 300].map((deg) => (
              <motion.span
                key={deg}
                className="absolute left-1/2 top-1/2 h-1 w-1 rounded-full bg-[var(--brand)]"
                initial={{ x: 0, y: 0, scale: 1 }}
                animate={{
                  x: Math.cos((deg * Math.PI) / 180) * 16,
                  y: Math.sin((deg * Math.PI) / 180) * 16,
                  scale: 0,
                }}
                transition={{ duration: 0.5, ease: [0.16, 1, 0.3, 1] }}
              />
            ))}
          </motion.span>
        )}
      </AnimatePresence>

      <motion.span
        key={active ? "on" : "off"}
        initial={{ scale: 0.4 }}
        animate={{ scale: [1.35, 1] }}
        transition={{ duration: 0.28, ease: [0.16, 1, 0.3, 1] }}
      >
        <Heart
          className={cn(
            "h-5 w-5 transition-colors",
            active && "fill-[var(--brand)] text-[var(--brand)]"
          )}
        />
      </motion.span>
    </button>
  );
}
