"use client";

import Link from "next/link";
import { Copy, Gift, Loader2, Scissors, Tag } from "lucide-react";
import { toast } from "sonner";

import { LandingNav } from "@/components/landing/landing-nav";
import { LandingFooter } from "@/components/landing/landing-footer";
import { MobileBottomNav } from "@/components/mobile-bottom-nav";
import { Button } from "@/components/ui/button";
import { usePublicCoupons } from "@/lib/api/queries/coupons";
import { formatTk } from "@/lib/utils";

export default function OffersPage() {
  const { data: coupons, isLoading, isError, refetch } = usePublicCoupons();

  async function copy(code: string) {
    try {
      await navigator.clipboard.writeText(code);
      toast.success(`${code} copied. Apply it at checkout.`);
    } catch {
      toast.info(`Use code ${code} at checkout.`);
    }
  }

  return (
    <div className="wasabi-app-shell min-h-dvh">
      <LandingNav />
      <main className="mx-auto min-h-[65dvh] max-w-[1180px] px-4 pb-16 pt-10 sm:px-6 sm:pt-16 lg:px-10 lg:pt-20">
        <header className="relative overflow-hidden border-b-4 border-[var(--menu-ink)] pb-7 sm:pb-10">
          <div className="pointer-events-none absolute -right-14 -top-16 h-48 w-48 rounded-full bg-[var(--menu-red)] opacity-95 sm:right-8 sm:h-64 sm:w-64" />
          <Tag className="pointer-events-none absolute right-5 top-4 h-28 w-28 rotate-12 text-[var(--menu-ink)] sm:right-20 sm:top-6 sm:h-40 sm:w-40" />
          <div className="relative max-w-[680px]">
            <p className="wasabi-page-kicker">Live counter offers</p>
            <h1 className="font-street mt-5 text-[clamp(3.1rem,10vw,7.6rem)] leading-[0.79]">CLIP IT.<br />CLAIM IT.</h1>
            <p className="mt-6 max-w-xl border-l-2 border-[var(--menu-red)] pl-4 text-sm font-semibold leading-6 text-black/55 dark:text-white/55">Copy an active code and apply it to an eligible basket at checkout. Minimum order and expiry rules still apply.</p>
          </div>
        </header>

        {isLoading && <div className="grid place-items-center py-24"><Loader2 className="h-7 w-7 animate-spin text-[var(--menu-red)]" /></div>}

        {isError && <div className="mt-10 border-2 border-[var(--menu-ink)] bg-[var(--menu-tan)] p-8 text-center"><p className="font-black">Offers couldn&apos;t load right now.</p><Button className="mt-4" variant="dark" onClick={() => refetch()}>Try again</Button></div>}

        {!isLoading && !isError && (coupons?.length ?? 0) === 0 && (
          <div className="mt-10 grid border-2 border-[var(--menu-ink)] sm:grid-cols-[0.7fr_1.3fr]">
            <div className="grid min-h-52 place-items-center bg-[var(--menu-red)] text-white"><Gift className="h-20 w-20" /></div>
            <div className="p-7 sm:p-10"><p className="wasabi-page-kicker">Counter empty</p><h2 className="font-street mt-3 text-3xl sm:text-5xl">No live offers today.</h2><p className="mt-3 text-sm text-black/55 dark:text-white/55">The full menu is still ready when you are.</p><Button asChild size="lg" className="mt-6"><Link href="/menu">Browse menu</Link></Button></div>
          </div>
        )}

        <div className="mt-10 grid gap-5 md:grid-cols-2">
          {(coupons ?? []).map((coupon, index) => (
            <article key={coupon.id} className="wasabi-ticket relative overflow-hidden border-2 border-[var(--menu-ink)] bg-[var(--menu-rice)]">
              <div className="grid min-h-20 grid-cols-[80px_1fr] border-b-2 border-dashed border-[var(--menu-ink)]">
                <span className="grid place-items-center bg-[var(--menu-red)] text-white"><Scissors className="h-7 w-7" /></span>
                <div className="flex items-center justify-between gap-3 px-5"><span className="text-[9px] font-black uppercase tracking-[0.18em] text-black/45 dark:text-white/45">Counter ticket {String(index + 1).padStart(2, "0")}</span><Tag className="h-4 w-4 text-[var(--menu-red)]" /></div>
              </div>
              <div className="p-6 sm:p-7">
                <p className="font-street text-[clamp(2rem,6vw,3.4rem)] leading-none">{coupon.discountType === "PERCENT" ? `${coupon.discountValue}% OFF` : `${formatTk(coupon.discountValue)} OFF`}</p>
                {coupon.description && <p className="mt-3 min-h-12 text-sm font-semibold leading-6 text-black/55 dark:text-white/55">{coupon.description}</p>}
                <div className="mt-6 grid grid-cols-[1fr_52px] border-2 border-[var(--menu-red)]">
                  <code className="flex min-w-0 items-center truncate px-4 font-sans text-base font-black tracking-[0.14em] text-[var(--menu-red)]">{coupon.code}</code>
                  <button aria-label={`Copy ${coupon.code}`} onClick={() => copy(coupon.code)} className="grid h-12 place-items-center bg-[var(--menu-red)] text-white transition-colors hover:bg-[var(--menu-ink)]"><Copy className="h-4 w-4" /></button>
                </div>
                <div className="mt-4 flex flex-wrap gap-x-4 gap-y-1 border-t border-black/15 pt-3 text-[10px] font-bold uppercase tracking-[0.06em] text-black/45 dark:border-white/15 dark:text-white/45">
                  {coupon.minOrderAmount != null && <span>Minimum {formatTk(coupon.minOrderAmount)}</span>}
                  {coupon.endsAt && <span>Ends {new Intl.DateTimeFormat("en-BD", { dateStyle: "medium" }).format(new Date(coupon.endsAt))}</span>}
                </div>
              </div>
            </article>
          ))}
        </div>
      </main>
      <LandingFooter />
      <MobileBottomNav />
    </div>
  );
}
