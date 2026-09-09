"use client";

import { useState } from "react";
import { Bike, Clock3, Flame, Search, ShoppingBag } from "lucide-react";

import { AlertDialog } from "@/components/ui/alert-dialog";
import { Button } from "@/components/ui/button";
import { Checkbox, QuantityStepper, Radio, Switch } from "@/components/ui/choice";
import { Chip, FilterChip } from "@/components/ui/chip";
import { EmptyState, Skeleton, Spinner, SummaryRow } from "@/components/ui/feedback";
import { Field } from "@/components/ui/field";
import { Input } from "@/components/ui/input";
import { Select } from "@/components/ui/select";
import { Textarea } from "@/components/ui/textarea";
import { notify } from "@/components/ui/toast";

function Section({
  title,
  note,
  children,
}: {
  title: string;
  note?: string;
  children: React.ReactNode;
}) {
  return (
    <section className="border-t border-[var(--border)] pt-8">
      <div className="mb-5">
        <h2 className="text-[17px] font-bold tracking-[-0.01em]">{title}</h2>
        {note && (
          <p className="mt-1 max-w-[60ch] text-[13px] text-[var(--foreground-mute)]">{note}</p>
        )}
      </div>
      {children}
    </section>
  );
}

export function Gallery() {
  const [confirmOpen, setConfirmOpen] = useState(false);
  const [dangerOpen, setDangerOpen] = useState(false);
  const [filters, setFilters] = useState<string[]>(["Popular"]);
  const [phone, setPhone] = useState("");
  const [tags, setTags] = useState(["Extra spicy", "No onion"]);
  const [qty, setQty] = useState(2);

  const toggle = (name: string) =>
    setFilters((f) => (f.includes(name) ? f.filter((x) => x !== name) : [...f, name]));

  return (
    <div className="wasabi-app-shell min-h-dvh px-5 py-12 sm:px-8 lg:px-12">
      <div className="mx-auto flex max-w-[900px] flex-col gap-10">
        <header>
          <p className="text-[9px] font-black uppercase tracking-[0.22em] text-[var(--brand)]">
            Internal
          </p>
          <h1 className="mt-2 text-[clamp(1.9rem,5vw,2.6rem)] font-bold leading-[1.05] tracking-[-0.02em]">
            Wasabi elements
          </h1>
          <p className="mt-4 max-w-[52ch] text-[14px] text-[var(--foreground-dim)]">
            Shared building blocks: soft radii, quiet borders and short, smooth
            transitions. Switch the theme to check both.
          </p>
        </header>

        <Section title="Chips" note="Status carries tone; filters are buttons and report aria-pressed.">
          <div className="flex flex-wrap items-center gap-2">
            <Chip tone="neutral">Pickup</Chip>
            <Chip tone="brand" dot>
              Preparing
            </Chip>
            <Chip tone="success" dot>
              Delivered
            </Chip>
            <Chip tone="warning">Delayed</Chip>
            <Chip tone="danger">Cancelled</Chip>
            <Chip tone="solid">Naga heat</Chip>
            <Chip tone="neutral" size="sm">
              150 Tk
            </Chip>
          </div>

          <div className="mt-4 flex flex-wrap gap-2">
            {["Popular", "Regular momo", "Momocola", "Premium", "Drinks"].map((f, i) => (
              <FilterChip
                key={f}
                selected={filters.includes(f)}
                count={[5, 4, 2, 3, 2][i]}
                onClick={() => toggle(f)}
              >
                {f}
              </FilterChip>
            ))}
          </div>

          <div className="mt-4 flex flex-wrap gap-2">
            {tags.map((t) => (
              <Chip
                key={t}
                tone="brand"
                onRemove={() => setTags((x) => x.filter((y) => y !== t))}
                removeLabel={`Remove ${t}`}
              >
                {t}
              </Chip>
            ))}
            {tags.length === 0 && (
              <span className="text-[13px] text-[var(--foreground-mute)]">All removed.</span>
            )}
          </div>
        </Section>

        <Section
          title="Snackbars"
          note="Top-centre, clear of the cart bar and tab bar. Errors linger longer than confirmations."
        >
          <div className="flex flex-wrap gap-2">
            <Button
              size="sm"
              variant="light"
              onClick={() =>
                notify.success("Added to your order", { description: "Chicken Momo, 150 Tk" })
              }
            >
              Success
            </Button>
            <Button
              size="sm"
              variant="light"
              onClick={() =>
                notify.error("Payment failed", { description: "bKash declined the transaction." })
              }
            >
              Error
            </Button>
            <Button
              size="sm"
              variant="light"
              onClick={() => notify.warning("Kitchen closes in 20 minutes")}
            >
              Warning
            </Button>
            <Button
              size="sm"
              variant="light"
              onClick={() =>
                notify.info("Rider assigned", {
                  action: { label: "Track", onClick: () => undefined },
                })
              }
            >
              With action
            </Button>
            <Button
              size="sm"
              variant="light"
              onClick={() =>
                notify.promise(new Promise((r) => setTimeout(r, 1600)), {
                  loading: "Placing your order...",
                  success: "Order placed",
                  error: "Could not place order",
                })
              }
            >
              Promise
            </Button>
          </div>
        </Section>

        <Section
          title="Alert dialogs"
          note="Cancel holds focus, so a stray Enter can never confirm a destructive action."
        >
          <div className="flex flex-wrap gap-2">
            <Button size="sm" onClick={() => setConfirmOpen(true)}>
              Confirm
            </Button>
            <Button size="sm" variant="dark" onClick={() => setDangerOpen(true)}>
              Destructive
            </Button>
          </div>

          <AlertDialog
            open={confirmOpen}
            onOpenChange={setConfirmOpen}
            title="Switch to pickup?"
            description="Your delivery address will be cleared and the 30 Tk delivery fee removed."
            confirmLabel="Switch to pickup"
            onConfirm={() => notify.success("Switched to pickup")}
          />
          <AlertDialog
            open={dangerOpen}
            onOpenChange={setDangerOpen}
            tone="danger"
            eyebrow="Order WSB-2043"
            title="Cancel this order?"
            description="The kitchen has already started preparing. Refunds take 3 to 5 working days."
            confirmLabel="Cancel order"
            cancelLabel="Keep it"
            onConfirm={async () => {
              await new Promise((r) => setTimeout(r, 1200));
              notify.success("Order cancelled", { description: "Refund is on its way." });
            }}
          />
        </Section>

        <Section
          title="Form"
          note="Field wires label, hint and error to the control so screen readers announce all three."
        >
          <div className="grid gap-5 sm:grid-cols-2">
            <Field label="Phone" hint="We only use this to reach you about the order." required>
              <Input
                placeholder="01XXXXXXXXX"
                inputMode="tel"
                value={phone}
                onChange={(e) => setPhone(e.target.value)}
              />
            </Field>

            <Field label="Phone" error="Enter an 11-digit Bangladeshi number." required>
              <Input placeholder="01XXXXXXXXX" defaultValue="0177" inputMode="tel" />
            </Field>

            <Field label="Delivery area" hint="Zones outside Dhanmondi add a surcharge.">
              <Select defaultValue="dhanmondi">
                <option value="dhanmondi">Dhanmondi</option>
                <option value="mohammadpur">Mohammadpur</option>
                <option value="gulshan">Gulshan</option>
              </Select>
            </Field>

            <Field label="Note for the kitchen" aside="0 / 200">
              <Textarea placeholder="Less chilli, extra sauce..." maxLength={200} />
            </Field>
          </div>

          <div className="mt-6 grid gap-3 sm:grid-cols-2">
            <Checkbox
              label="Extra momo sauce"
              description="House chilli and garlic"
              trailing="+ 30 Tk"
              defaultChecked
            />
            <Checkbox label="Wooden chopsticks" trailing="Free" />
            <Radio
              name="fulfilment"
              label="Delivery"
              description="20 min, 30 Tk from Dhanmondi"
              defaultChecked
            />
            <Radio name="fulfilment" label="Pickup" description="Ready in 15 min at the counter" />
          </div>

          <div className="mt-6 flex flex-col gap-4 rounded-xl border border-[var(--border)] bg-[var(--surface)] p-5">
            <Switch
              label="Order updates by SMS"
              description="Status changes and rider details."
              defaultChecked
            />
            <Switch label="Offers and new dishes" description="At most one message a week." />
            <Switch label="Contactless handover" disabled />
          </div>
        </Section>

        <Section
          title="Basket line"
          note="Stepper digits are tabular so the row holds still past 9, and minus becomes a bin at 1."
        >
          <div className="flex flex-wrap items-center justify-between gap-4 rounded-xl border border-[var(--border)] bg-[var(--surface)] p-4">
            <div className="flex min-w-0 flex-col">
              <span className="text-[15px] font-black tracking-[-0.005em]">Chicken Momo</span>
              <span className="mt-0.5 text-[12px] text-[var(--foreground-mute)]">
                Extra momo sauce
              </span>
            </div>
            <div className="flex items-center gap-4">
              <span className="text-[16px] font-black tabular-nums">{150 * qty} Tk</span>
              <QuantityStepper value={qty} onChange={setQty} label="Chicken Momo" />
            </div>
          </div>

          <div className="mt-5 flex flex-col gap-2.5 rounded-xl border border-[var(--border)] bg-[var(--surface)] p-4">
            <SummaryRow label="Subtotal" value={`${150 * qty} Tk`} />
            <SummaryRow label="Packaging" value="15 Tk" />
            <SummaryRow label="Delivery" value="30 Tk" />
            <SummaryRow label="Total" value={`${150 * qty + 45} Tk`} emphasis />
          </div>
        </Section>

        <Section title="Buttons">
          <div className="flex flex-wrap items-center gap-2">
            <Button>Build an order</Button>
            <Button variant="dark">How it moves</Button>
            <Button variant="light">Cancel</Button>
            <Button variant="ghost">Skip</Button>
            <Button size="sm">Small</Button>
            <Button size="icon" aria-label="Search">
              <Search className="h-4 w-4" />
            </Button>
            <Button disabled>Disabled</Button>
            <Button className="rounded-lg">Rounded</Button>
          </div>
        </Section>

        <Section
          title="Loading and empty"
          note="Skeletons take the shape of the thing they stand in for; empty states are only for genuinely empty lists."
        >
          <div className="grid gap-3 sm:grid-cols-[136px_1fr_auto] sm:items-center">
            <Skeleton className="h-[132px] w-full rounded-xl sm:w-[136px]" />
            <div className="flex flex-col gap-2">
              <Skeleton className="h-4 w-2/3 rounded-md" />
              <Skeleton className="h-3 w-full rounded-md" />
              <Skeleton className="h-3 w-4/5 rounded-md" />
            </div>
            <Skeleton className="h-11 w-11 rounded-full" />
          </div>

          <div className="mt-4 flex items-center gap-3 text-[13px] text-[var(--foreground-dim)]">
            <Spinner className="h-5 w-5 text-[var(--brand)]" /> Checking the kitchen...
          </div>

          <div className="mt-6 rounded-xl border border-[var(--border)] bg-[var(--surface)]">
            <EmptyState
              icon={<ShoppingBag className="h-8 w-8" />}
              title="Your basket is empty"
              description="Add a few momo and they will show up here, ready to send to the kitchen."
              action={<Button size="sm" className="rounded-lg">Browse the menu</Button>}
            />
          </div>
        </Section>

        <Section title="Inline meta" note="The small stuff that carries most of the ordering information.">
          <div className="flex flex-wrap items-center gap-x-6 gap-y-3 text-[11px] font-black uppercase tracking-[0.1em] text-[var(--foreground-dim)]">
            <span className="inline-flex items-center gap-2">
              <Bike className="h-4 w-4 text-[var(--brand)]" /> Delivery 30 Tk
            </span>
            <span className="inline-flex items-center gap-2">
              <Clock3 className="h-4 w-4 text-[var(--brand)]" /> 20 min prep
            </span>
            <span className="inline-flex items-center gap-2">
              <Flame className="h-4 w-4 text-[var(--brand)]" /> Naga heat
            </span>
          </div>
        </Section>
      </div>
    </div>
  );
}
