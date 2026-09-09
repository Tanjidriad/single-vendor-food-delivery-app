"use client";

import Link from "next/link";
import { motion } from "framer-motion";
import { Heart, Loader2, Plus } from "lucide-react";
import { toast } from "sonner";

import { TopBar } from "@/components/landing/top-bar";
import { LandingNav } from "@/components/landing/landing-nav";
import { LandingFooter } from "@/components/landing/landing-footer";
import { MobileBottomNav } from "@/components/mobile-bottom-nav";
import { FoodImage } from "@/components/food-image";
import { FavoriteButton } from "@/components/menu/favorite-button";
import { Button } from "@/components/ui/button";
import { useAuth } from "@/lib/auth/use-auth";
import { useFavorites } from "@/lib/api/queries/favorites";
import { useCartStore } from "@/store/cart-store";
import { formatTk } from "@/lib/utils";
import type { Favorite } from "@/types";

export default function FavoritesPage() {
  const { isAuthenticated, hydrated } = useAuth();
  const { data: favorites, isLoading, isError, refetch } = useFavorites();

  if (hydrated && !isAuthenticated) {
    return (
      <Shell>
        <div className="mx-auto flex max-w-md flex-col items-center px-4 py-24 text-center">
          <span className="grid h-16 w-16 place-items-center bg-[var(--menu-red)] text-white">
            <Heart className="h-7 w-7" />
          </span>
          <h1 className="font-street mt-5 text-3xl">
            Sign in to see your favourites
          </h1>
          <p className="mt-2 text-sm text-[var(--foreground-dim)]">
            Save the dishes you love and reorder them in a tap.
          </p>
          <Link href="/login?next=/favorites" className="mt-6">
            <Button size="lg">Sign in</Button>
          </Link>
        </div>
      </Shell>
    );
  }

  const list = favorites ?? [];

  return (
    <Shell>
      <div className="mx-auto max-w-[980px] px-4 py-10 sm:px-6 sm:py-16 lg:py-20">
        <p className="wasabi-page-kicker">
          Favourites
        </p>
        <h1 className="font-street mt-4 text-[clamp(3rem,9vw,6.8rem)] leading-[0.82]">
          Saved for<br />the next box.
        </h1>

        {isLoading && (
          <div className="flex justify-center py-20">
            <Loader2 className="h-7 w-7 animate-spin text-[var(--foreground-mute)]" />
          </div>
        )}

        {isError && (
          <div className="mt-8 border-2 border-[var(--menu-ink)] bg-[var(--menu-tan)] p-8 text-center">
            <p className="text-sm text-[var(--foreground-dim)]">
              We couldn&apos;t load your favourites just now.
            </p>
            <button
              onClick={() => refetch()}
              className="mt-3 text-sm font-semibold text-[var(--brand)] underline underline-offset-4"
            >
              Try again
            </button>
          </div>
        )}

        {!isLoading && !isError && list.length === 0 && (
          <div className="mt-10 flex flex-col items-center border-2 border-[var(--menu-ink)] bg-[var(--menu-rice)] px-6 py-16 text-center">
            <span className="grid h-14 w-14 place-items-center bg-[var(--menu-red)] text-white">
              <Heart className="h-6 w-6" />
            </span>
            <h2 className="font-street mt-4 text-2xl">
              No favourites yet
            </h2>
            <p className="mt-2 max-w-[36ch] text-sm text-[var(--foreground-dim)]">
              Tap the heart on any dish and it&apos;ll be waiting for you here.
            </p>
            <Link href="/menu" className="mt-6">
              <Button size="lg">Browse the menu</Button>
            </Link>
          </div>
        )}

        {!isLoading && list.length > 0 && (
          <div className="mt-8 grid gap-4 sm:grid-cols-2">
            {list.map((fav, i) => (
              <FavoriteCard key={fav.id} favorite={fav} index={i} />
            ))}
          </div>
        )}
      </div>
    </Shell>
  );
}

function FavoriteCard({
  favorite,
  index,
}: {
  favorite: Favorite;
  index: number;
}) {
  const add = useCartStore((s) => s.add);
  const item = favorite.menuItem;

  function handleAdd() {
    add(item, [], 1);
    toast.success(`${item.name} added`);
  }

  return (
    <motion.article
      initial={{ opacity: 0, y: 16 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{
        duration: 0.4,
        ease: [0.16, 1, 0.3, 1],
        delay: (index % 4) * 0.05,
      }}
      className="group flex items-stretch gap-4 border border-black/15 bg-[var(--menu-rice)] p-3 transition-colors hover:border-[var(--menu-red)] dark:border-white/15"
    >
      <div className="flex min-w-0 flex-1 flex-col py-0.5">
        <h3 className="font-street text-[1.05rem] leading-[1.05]">
          {item.name}
        </h3>
        {item.description && (
          <p className="mt-2 line-clamp-2 text-[13px] leading-[1.6] text-[var(--foreground-dim)]">
            {item.description}
          </p>
        )}
        <div className="mt-auto pt-4">
          <span className="text-[1.05rem] font-black tabular-nums text-[var(--brand)]">
            {formatTk(item.price)}
          </span>
        </div>
      </div>
      <div className="relative h-[120px] w-[120px] flex-none self-center">
        <FoodImage
          src={item.imageUrl}
          alt={item.name}
          className="h-full w-full rounded-none"
          sizes="120px"
          loading="eager"
        />
        <FavoriteButton
          menuItemId={item.id}
          itemName={item.name}
          className="absolute left-2 top-2 h-9 w-9"
        />
        <button
          aria-label={`Add ${item.name} to cart`}
          onClick={handleAdd}
          className="absolute bottom-0 right-0 grid h-11 w-11 place-items-center bg-[var(--menu-red)] text-white transition-colors hover:bg-[var(--menu-ink)] focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-red-200"
        >
          <Plus className="h-[18px] w-[18px]" strokeWidth={3} />
        </button>
      </div>
    </motion.article>
  );
}

function Shell({ children }: { children: React.ReactNode }) {
  return (
    <div className="wasabi-app-shell min-h-dvh">
      <div className="hidden sm:block">
        <TopBar />
      </div>
      <LandingNav />
      <main>
        {children}
      </main>
      <LandingFooter />
      <MobileBottomNav />
    </div>
  );
}
