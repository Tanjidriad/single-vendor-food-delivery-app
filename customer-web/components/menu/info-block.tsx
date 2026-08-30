"use client";

import {
  ArrowUpRight,
  Bike,
  Clock3,
  Mail,
  MapPin,
  Phone,
  ShoppingBag,
} from "lucide-react";

import { ToriiMark } from "@/components/brand";
import { useRestaurant } from "@/lib/api/queries/menu";
import {
  RESTAURANT_INFO,
  getOpenStatus,
  groupedHours,
} from "@/lib/restaurant-info";

export function InfoBlock() {
  const { data: restaurant } = useRestaurant();
  const operatingHours = restaurant?.operatingHours?.length
    ? restaurant.operatingHours
    : RESTAURANT_INFO.operatingHours;
  const hours = groupedHours(operatingHours);
  const status = getOpenStatus(operatingHours);
  const phone = restaurant?.phone ?? RESTAURANT_INFO.phone;
  const email = restaurant?.email ?? RESTAURANT_INFO.email;
  const address = [
    restaurant?.addressLine ?? RESTAURANT_INFO.addressLine,
    restaurant?.city ?? RESTAURANT_INFO.city,
    restaurant?.country ?? RESTAURANT_INFO.country,
  ]
    .filter(Boolean)
    .join(", ");

  return (
    <section
      aria-labelledby="counter-notes-title"
      className="mx-auto max-w-[1440px] px-4 py-12 sm:px-6 sm:py-16 lg:px-10 lg:py-20"
    >
      <header className="grid gap-5 border-b-4 border-[var(--menu-ink)] pb-5 sm:grid-cols-[minmax(0,1fr)_auto] sm:items-end sm:pb-7">
        <div>
          <p className="mb-2 flex items-center gap-2 text-[10px] font-black uppercase tracking-[0.22em] text-[var(--menu-red)]">
            <span className="h-2 w-2 bg-current" /> Counter notes
          </p>
          <h2
            id="counter-notes-title"
            className="font-street max-w-3xl text-[clamp(2.35rem,8vw,5.6rem)] leading-[0.88]"
          >
            Plan your
            <br />
            momo run.
          </h2>
        </div>
        <p className="max-w-[290px] border-l-2 border-[var(--menu-red)] pl-4 text-xs font-semibold leading-5 text-black/55 dark:text-white/55 sm:mb-1">
          Kitchen hours, direct contact and hand-off options—checked before you place the order.
        </p>
      </header>

      <div className="grid border-x border-b border-black/20 lg:grid-cols-[0.82fr_1.08fr_1.1fr] dark:border-white/20">
        <div className="relative min-h-[255px] overflow-hidden bg-[var(--menu-red)] p-6 text-white sm:p-8 lg:min-h-[390px]">
          <ToriiMark className="absolute -bottom-8 -right-8 h-48 w-56 text-black/15 sm:h-60 sm:w-72" />
          <div className="relative z-10 flex h-full flex-col justify-between gap-14">
            <div className="flex items-center justify-between gap-4 border-b border-white/35 pb-3 text-[10px] font-black uppercase tracking-[0.18em]">
              <span>Kitchen signal</span>
              <span className="flex items-center gap-2">
                <span className={`h-2.5 w-2.5 ${status?.isOpen ? "animate-pulse bg-white" : "bg-black/45"}`} />
                Live
              </span>
            </div>
            <div aria-live="polite">
              <p className="font-street text-[clamp(3.5rem,11vw,6.5rem)] leading-[0.75] tracking-[-0.07em] lg:text-[clamp(3rem,5.2vw,4.8rem)]">
                {status?.isOpen ? "OPEN" : "CLOSED"}
              </p>
              <p className="mt-5 max-w-[240px] border-t border-white/35 pt-3 text-xs font-black uppercase tracking-[0.1em]">
                {status?.label ?? "Hours are being updated"}
              </p>
            </div>
          </div>
        </div>

        <div className="bg-[var(--menu-tan)] p-6 sm:p-8 lg:min-h-[390px]">
          <div className="mb-6 flex items-center justify-between border-b-2 border-[var(--menu-ink)] pb-3">
            <h3 className="font-street text-xl uppercase leading-none">Service board</h3>
            <Clock3 className="h-5 w-5 text-[var(--menu-red)]" />
          </div>
          {hours.length > 0 ? (
            <dl className="divide-y divide-black/20 text-xs">
              {hours.map((row) => (
                <div key={row.label} className="grid grid-cols-[minmax(68px,0.6fr)_1.4fr] gap-4 py-3.5 first:pt-0">
                  <dt className="font-black uppercase tracking-[0.08em]">{row.label}</dt>
                  <dd className="text-right font-semibold tabular-nums text-black/60 dark:text-white/60">
                    {row.value}
                  </dd>
                </div>
              ))}
            </dl>
          ) : (
            <p className="max-w-[250px] text-sm font-semibold leading-6 text-black/55 dark:text-white/55">
              The weekly service board is being updated. Check with the kitchen before travelling.
            </p>
          )}
        </div>

        <div className="flex min-h-[320px] flex-col bg-[var(--menu-rice)] lg:min-h-[390px] lg:border-l lg:border-black/20 dark:lg:border-white/20">
          <div className="p-6 sm:p-8">
            <p className="text-[10px] font-black uppercase tracking-[0.2em] text-[var(--menu-red)]">Kitchen line</p>
            <h3 className="font-street mt-2 text-3xl leading-none sm:text-4xl">Talk to the counter.</h3>
            <p className="mt-4 max-w-sm text-xs font-semibold leading-5 text-black/50 dark:text-white/50">
              For allergy questions or a special request, contact the kitchen before ordering.
            </p>
          </div>

          <div className="mt-auto border-t border-black/20 dark:border-white/20">
            {phone && (
              <ContactRow href={`tel:${phone.replace(/\s/g, "")}`} icon={Phone} label="Call" value={phone} />
            )}
            {email && <ContactRow href={`mailto:${email}`} icon={Mail} label="Email" value={email} />}
            {address ? (
              <div className="grid min-h-16 grid-cols-[28px_1fr] items-center gap-3 border-b border-black/20 px-6 py-4 text-xs dark:border-white/20 sm:px-8">
                <MapPin className="h-4 w-4 text-[var(--menu-red)]" />
                <span className="font-semibold leading-5 text-black/60 dark:text-white/60">{address}</span>
              </div>
            ) : null}
            {!phone && !email && !address && (
              <p className="px-6 py-5 text-xs font-semibold leading-5 text-black/50 dark:text-white/50 sm:px-8">
                Direct kitchen contact details are being updated.
              </p>
            )}
          </div>
        </div>
      </div>

      <div className="grid bg-[var(--menu-ink)] text-[var(--menu-rice)] sm:grid-cols-2">
        <FulfilmentStrip
          icon={Bike}
          label="Door delivery"
          body="Route, fee and arrival estimate are confirmed for your address at checkout."
        />
        <FulfilmentStrip
          icon={ShoppingBag}
          label="Counter pickup"
          body="Order ahead, skip the wait and collect directly from the kitchen."
          bordered
        />
      </div>
    </section>
  );
}

function ContactRow({
  href,
  icon: Icon,
  label,
  value,
}: {
  href: string;
  icon: typeof Phone;
  label: string;
  value: string;
}) {
  return (
    <a
      href={href}
      className="group grid min-h-16 grid-cols-[28px_1fr_auto] items-center gap-3 border-b border-black/20 px-6 py-3 text-xs transition-colors hover:bg-[var(--menu-red)] hover:text-white focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-inset focus-visible:ring-red-200 dark:border-white/20 sm:px-8"
    >
      <Icon className="h-4 w-4 text-[var(--menu-red)] group-hover:text-white" />
      <span>
        <span className="block text-[9px] font-black uppercase tracking-[0.16em] opacity-45">{label}</span>
        <span className="mt-0.5 block font-black">{value}</span>
      </span>
      <ArrowUpRight className="h-4 w-4" />
    </a>
  );
}

function FulfilmentStrip({
  icon: Icon,
  label,
  body,
  bordered = false,
}: {
  icon: typeof Bike;
  label: string;
  body: string;
  bordered?: boolean;
}) {
  return (
    <div className={`grid grid-cols-[42px_1fr] gap-4 p-5 sm:p-6 ${bordered ? "border-t border-white/20 sm:border-l sm:border-t-0" : ""}`}>
      <span className="grid h-10 w-10 place-items-center bg-[var(--menu-red)] text-white">
        <Icon className="h-5 w-5" />
      </span>
      <div>
        <p className="font-street text-base uppercase leading-none">{label}</p>
        <p className="mt-2 max-w-md text-[11px] font-semibold leading-4 text-white/50">{body}</p>
      </div>
    </div>
  );
}
