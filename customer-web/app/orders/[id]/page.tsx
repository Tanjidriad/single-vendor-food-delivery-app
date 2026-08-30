"use client";

import { use, useEffect, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { toast } from "sonner";
import {
  ArrowLeft,
  Bike,
  Check,
  CheckCircle2,
  Clock,
  KeyRound,
  Loader2,
  MapPin,
  MessageSquareWarning,
  Phone,
  ShoppingBag,
  Smartphone,
  XCircle,
} from "lucide-react";


import { TopBar } from "@/components/landing/top-bar";
import { LandingNav } from "@/components/landing/landing-nav";
import { LandingFooter } from "@/components/landing/landing-footer";
import { MobileBottomNav } from "@/components/mobile-bottom-nav";
import { Button } from "@/components/ui/button";
import { LeaveReview } from "@/components/orders/leave-review";
import { ReportProblemSheet } from "@/components/support/report-problem-sheet";
import { useAuth } from "@/lib/auth/use-auth";

import {
  useOrder,
  useCancelOrder,
  useConfirmDelivery,
  useReorder,
} from "@/lib/api/queries/orders";
import { useInitiateOnlinePayment } from "@/lib/api/queries/payments";
import {
  getRealtimeAccessToken,
  getSocket,
  REALTIME_EVENTS,
} from "@/lib/realtime/socket";
import { formatTk } from "@/lib/utils";
import { ApiError } from "@/lib/api/client";
import { isTrustedPaymentUrl } from "@/lib/payments";
import {
  STATUS_LABELS,
  canCancel,
  currentStepIndex,
  isCancelledLike,
  isTerminal,
  progressSteps,
} from "@/lib/order-status";
import type { Order, RiderLocation } from "@/types";

export default function OrderPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = use(params);
  const router = useRouter();
  const { isAuthenticated, hydrated } = useAuth();

  const { data: order, isLoading, isError, refetch } = useOrder(id, {
    poll: true,
  });
  const cancelOrder = useCancelOrder();
  const confirmDelivery = useConfirmDelivery();
  const reorder = useReorder();
  const initiatePayment = useInitiateOnlinePayment();

  const [riderLoc, setRiderLoc] = useState<RiderLocation | null>(null);
  const [reporting, setReporting] = useState(false);


  // Realtime: join the order room and react to live status / rider updates.
  useEffect(() => {
    if (!isAuthenticated || !id) return;
    let disposed = false;
    let socket: ReturnType<typeof getSocket> | null = null;
    const join = () => socket?.emit("order:join", { orderId: id });

    const onStatus = (payload?: { id?: string; orderId?: string }) => {
      const payloadOrderId = payload?.orderId ?? payload?.id;
      if (!payloadOrderId || payloadOrderId === id) void refetch();
    };
    const onRider = (payload: RiderLocation) => {
      if (!payload.orderId || payload.orderId === id) setRiderLoc(payload);
    };
    void getRealtimeAccessToken()
      .then((token) => {
        if (disposed) return;
        socket = getSocket(token);
        join();
        socket.on("connect", join);
        socket.on(REALTIME_EVENTS.orderStatusChanged, onStatus);
        socket.on(REALTIME_EVENTS.riderLocation, onRider);
      })
      .catch(() => undefined);

    return () => {
      disposed = true;
      socket?.emit("order:leave", { orderId: id });
      socket?.off("connect", join);
      socket?.off(REALTIME_EVENTS.orderStatusChanged, onStatus);
      socket?.off(REALTIME_EVENTS.riderLocation, onRider);
    };
  }, [isAuthenticated, id, refetch]);

  if (hydrated && !isAuthenticated) {
    return (
      <Shell>
        <div className="mx-auto max-w-md px-4 py-24 text-center">
          <h1 className="font-street text-3xl">Sign in to view this order</h1>
          <Link href={`/login?next=/orders/${id}`} className="mt-6 inline-block">
            <Button size="lg">Sign in</Button>
          </Link>
        </div>
      </Shell>
    );
  }

  if (isLoading) {
    return (
      <Shell>
        <div className="mx-auto flex max-w-[820px] justify-center px-4 py-24">
          <Loader2 className="h-7 w-7 animate-spin text-[var(--foreground-mute)]" />
        </div>
      </Shell>
    );
  }

  if (isError || !order) {
    return (
      <Shell>
        <div className="mx-auto max-w-md px-4 py-24 text-center">
          <h1 className="font-street text-3xl">Order not found</h1>
          <p className="mt-2 text-sm text-[var(--foreground-dim)]">
            We couldn&apos;t load this order. It may have been removed.
          </p>
          <Link href="/orders" className="mt-6 inline-block">
            <Button size="lg" variant="light">
              View your orders
            </Button>
          </Link>
        </div>
      </Shell>
    );
  }

  const serial = order.dailySerial
    ? `#${String(order.dailySerial).padStart(3, "0")}`
    : `#${order.orderNumber.slice(-6)}`;
  const cancelled = isCancelledLike(order.status);
  const showConfirm =
    order.orderType === "DELIVERY" &&
    order.status === "ON_THE_WAY" &&
    !!order.deliveryService;

  return (
    <Shell>
      <div className="mx-auto max-w-[980px] px-4 py-8 sm:px-6 sm:py-12 lg:py-16">
        <Link
          href="/orders"
          className="inline-flex items-center gap-2 text-sm font-semibold text-[var(--foreground-dim)] transition-colors hover:text-[var(--foreground)]"
        >
          <ArrowLeft className="h-4 w-4" /> All orders
        </Link>

        {/* Header */}
        <div className="mt-4 flex flex-wrap items-end justify-between gap-4">
          <div>
            <p className="wasabi-page-kicker">
              Order {serial}
            </p>
            <h1 className="font-street mt-3 text-[clamp(2.5rem,7vw,5.2rem)] leading-[0.86]">
              {cancelled
                ? STATUS_LABELS[order.status]
                : order.status === "DELIVERED"
                  ? "Delivered — enjoy!"
                  : "We're on it"}
            </h1>
          </div>
          <span className="inline-flex items-center gap-2 border-2 border-[var(--menu-ink)] bg-[var(--menu-rice)] px-3.5 py-2 text-xs font-black uppercase tracking-[0.06em]">
            {order.orderType === "DELIVERY" ? (
              <Bike className="h-4 w-4 text-[var(--brand)]" />
            ) : (
              <ShoppingBag className="h-4 w-4 text-[var(--brand)]" />
            )}
            {order.orderType === "DELIVERY" ? "Delivery" : "Pickup"}
          </span>
        </div>

        {/* Tracker */}
        {cancelled ? (
          <div className="mt-6 flex items-center gap-3 border-2 border-[var(--menu-ink)] bg-[var(--menu-tan)] p-5">
            <XCircle className="h-6 w-6 flex-none text-[var(--brand)]" />
            <p className="text-sm text-[var(--foreground-dim)]">
              This order was {order.status.toLowerCase()}.
              {order.cancelledReason ? ` ${order.cancelledReason}` : ""}
            </p>
          </div>
        ) : (
          <Tracker order={order} />
        )}

        {/* ETA / rider */}
        {!cancelled && order.status !== "DELIVERED" && (
          <div className="mt-4 grid gap-4 sm:grid-cols-2">
            {order.routeEtaMinutes != null && order.orderType === "DELIVERY" && (
              <InfoCard
                icon={Clock}
                title="Estimated arrival"
                value={`~${order.routeEtaMinutes} min`}
              />
            )}
            {order.prepMinutes != null && (
              <InfoCard
                icon={Clock}
                title="Kitchen prep time"
                value={`~${order.prepMinutes} min`}
              />
            )}
            {order.assignment?.rider?.user?.phone && (
              <a href={`tel:${order.assignment.rider.user.phone}`}>
                <InfoCard
                  icon={Phone}
                  title="Your rider"
                  value={order.assignment.rider.user.phone}
                  interactive
                />
              </a>
            )}
          </div>
        )}

        {/* Live map when a rider is on the way */}
        {order.status === "ON_THE_WAY" && order.orderType === "DELIVERY" && (
          <LiveMap order={order} rider={riderLoc} />
        )}

        {order.deliveryOtp &&
          order.orderType === "DELIVERY" &&
          order.status === "ON_THE_WAY" && (
            <div className="mt-4 border-2 border-[var(--menu-red)] bg-[var(--menu-tan)] p-5 sm:flex sm:items-center sm:justify-between sm:gap-5">
              <div className="flex items-start gap-3">
                <span className="grid h-11 w-11 flex-none place-items-center bg-[var(--menu-red)] text-white">
                  <KeyRound className="h-5 w-5" />
                </span>
                <div>
                  <h2 className="font-street text-lg">
                    Delivery code
                  </h2>
                  <p className="mt-1 text-sm text-[var(--foreground-dim)]">
                    Tell this code to your Wasabi rider only after receiving the order.
                  </p>
                </div>
              </div>
              <p className="font-street mt-4 border-2 border-[var(--menu-ink)] bg-[var(--menu-rice)] px-5 py-3 text-center text-3xl tracking-[0.24em] tabular-nums sm:mt-0">
                {order.deliveryOtp}
              </p>
            </div>
          )}

        {/* Actions */}
        <div className="mt-5 flex flex-wrap gap-3">
          {order.paymentMethod === "ONLINE" &&
            order.paymentStatus !== "PAID" &&
            !isTerminal(order.status) && (
              <Button
                onClick={() =>
                  initiatePayment.mutate(order.id, {
                    onSuccess: (payment) => {
                      if (!isTrustedPaymentUrl(payment.checkoutUrl)) {
                        toast.error("The payment gateway returned an unsafe URL.");
                        return;
                      }
                      window.location.assign(payment.checkoutUrl);
                    },
                    onError: (error) =>
                      toast.error(
                        error instanceof ApiError
                          ? error.message
                          : "Couldn't open bKash. Please try again."
                      ),
                  })
                }
                disabled={initiatePayment.isPending}
              >
                {initiatePayment.isPending ? (
                  <Loader2 className="h-5 w-5 animate-spin" />
                ) : (
                  <Smartphone className="h-5 w-5" />
                )}
                Pay with bKash
              </Button>
            )}
          {showConfirm && (
            <Button
              onClick={() =>
                confirmDelivery.mutate(order.id, {
                  onSuccess: () => toast.success("Thanks for confirming!"),
                  onError: (e) =>
                    toast.error(
                      e instanceof ApiError ? e.message : "Couldn't confirm."
                    ),
                })
              }
              disabled={confirmDelivery.isPending}
            >
              <CheckCircle2 className="h-5 w-5" /> I&apos;ve received my order
            </Button>
          )}
          {canCancel(order.status) && (
            <Button
              variant="light"
              onClick={() => {
                if (!confirm("Cancel this order?")) return;
                cancelOrder.mutate(
                  { id: order.id },
                  {
                    onSuccess: () => toast.success("Order cancelled."),
                    onError: (e) =>
                      toast.error(
                        e instanceof ApiError ? e.message : "Couldn't cancel."
                      ),
                  }
                );
              }}
              disabled={cancelOrder.isPending}
            >
              Cancel order
            </Button>
          )}
          {isTerminal(order.status) && (
            <Button
              variant="light"
              onClick={() =>
                reorder.mutate(order.id, {
                  onSuccess: () => {
                    toast.success("Added to a new order.");
                    router.push("/menu");
                  },
                  onError: (e) =>
                    toast.error(
                      e instanceof ApiError ? e.message : "Couldn't reorder."
                    ),
                })
              }
              disabled={reorder.isPending}
            >
              Order again
            </Button>
          )}
          <Button variant="ghost" onClick={() => setReporting(true)}>
            <MessageSquareWarning className="h-5 w-5" /> Report a problem
          </Button>
        </div>

        {order.status === "DELIVERED" && <LeaveReview orderId={order.id} />}


        {/* Items + totals */}
        <div className="mt-8 grid gap-4 lg:grid-cols-[1.3fr_1fr]">
          <div className="border-2 border-[var(--menu-ink)] bg-[var(--menu-rice)] p-5 sm:p-6">
            <h2 className="font-street text-xl">Order slip</h2>
            <ul className="mt-4 space-y-3">
              {order.items.map((it) => (
                <li key={it.id} className="flex items-start gap-3">
                  <span className="grid h-7 min-w-7 place-items-center rounded-full bg-[var(--surface-sunken)] px-1.5 text-xs font-bold">
                    {it.quantity}×
                  </span>
                  <div className="min-w-0 flex-1">
                    <p className="text-sm font-semibold leading-tight">
                      {it.name}
                    </p>
                    {it.addons.length > 0 && (
                      <p className="text-xs text-[var(--foreground-mute)]">
                        {it.addons.map((a) => a.name).join(", ")}
                      </p>
                    )}
                    {it.notes && (
                      <p className="text-xs italic text-[var(--foreground-mute)]">
                        “{it.notes}”
                      </p>
                    )}
                  </div>
                  <span className="text-sm font-bold tabular-nums">
                    {formatTk(it.lineTotal)}
                  </span>
                </li>
              ))}
            </ul>
          </div>

          <div className="border-2 border-[var(--menu-ink)] bg-[var(--menu-tan)] p-5 sm:p-6">
            <h2 className="font-street text-xl">Counter total</h2>
            <dl className="mt-4 space-y-2.5 text-sm">
              <Row label="Subtotal" value={formatTk(order.subtotal)} />
              {order.discountAmount > 0 && (
                <Row
                  label="Discount"
                  value={`− ${formatTk(order.discountAmount)}`}
                  accent
                />
              )}
              {order.packagingFee > 0 && (
                <Row label="Packaging" value={formatTk(order.packagingFee)} />
              )}
              {order.taxAmount > 0 && (
                <Row label="Tax" value={formatTk(order.taxAmount)} />
              )}
              {order.orderType === "DELIVERY" && (
                <Row
                  label="Delivery fee"
                  value={
                    order.deliveryFee === 0
                      ? "Free"
                      : formatTk(order.deliveryFee)
                  }
                />
              )}
              <div className="flex items-center justify-between border-t border-[var(--border-subtle)] pt-3">
                <dt className="font-display text-base font-black">Total</dt>
                <dd className="font-display text-lg font-black tabular-nums">
                  {formatTk(order.grandTotal)}
                </dd>
              </div>
            </dl>

            <div className="mt-4 border-t border-[var(--border-subtle)] pt-4 text-sm">
              <p className="font-semibold">
                {order.paymentMethod === "COD"
                  ? "Cash on delivery"
                  : order.paymentMethod === "ONLINE"
                    ? `bKash · ${order.paymentStatus.toLowerCase()}`
                    : order.paymentMethod}
              </p>
              {order.orderType === "DELIVERY" && order.deliveryAddress && (
                <p className="mt-2 flex items-start gap-2 text-[var(--foreground-dim)]">
                  <MapPin className="mt-0.5 h-4 w-4 flex-none text-[var(--brand)]" />
                  {order.deliveryAddress}
                </p>
              )}
            </div>
          </div>
        </div>
      </div>

      <ReportProblemSheet
        orderId={order.id}
        open={reporting}
        onClose={() => setReporting(false)}
      />
    </Shell>
  );
}

function Tracker({ order }: { order: Order }) {

  const steps = progressSteps(order.orderType);
  const current = currentStepIndex(order.status, order.orderType);

  return (
    <div className="mt-6 rounded-[14px] border border-[var(--border-subtle)] bg-[var(--surface)] p-5 sm:p-6">
      <ol className="grid gap-0 sm:flex sm:gap-2">
        {steps.map((step, i) => {
          const done = i < current;
          const active = i === current;
          return (
            <li
              key={step.status}
              className="relative flex items-center gap-3 py-2 sm:min-w-0 sm:flex-1 sm:flex-col sm:items-start sm:py-0"
            >
              {/* connector (desktop) */}
              {i < steps.length - 1 && (
                <span
                  className={`absolute left-[15px] top-9 h-[calc(100%-1.5rem)] w-0.5 sm:left-0 sm:top-[15px] sm:h-0.5 sm:w-full ${
                    done ? "bg-[var(--brand)]" : "bg-[var(--border)]"
                  }`}
                />
              )}
              <span
                className={`relative z-10 grid h-8 w-8 flex-none place-items-center rounded-full border-2 ${
                  done
                    ? "border-[var(--brand)] bg-[var(--brand)] text-white"
                    : active
                      ? "border-[var(--brand)] bg-[var(--surface)] text-[var(--brand)]"
                      : "border-[var(--border)] bg-[var(--surface)] text-[var(--foreground-mute)]"
                }`}
              >
                {done ? (
                  <Check className="h-4 w-4" />
                ) : (
                  <span
                    className={`h-2 w-2 rounded-full ${active ? "bg-[var(--brand)]" : "bg-[var(--border)]"} ${active ? "animate-pulse" : ""}`}
                  />
                )}
              </span>
              <span
                className={`text-[13px] font-semibold sm:mt-2 ${
                  active
                    ? "text-[var(--foreground)]"
                    : done
                      ? "text-[var(--foreground-dim)]"
                      : "text-[var(--foreground-mute)]"
                }`}
              >
                {step.label}
              </span>
            </li>
          );
        })}
      </ol>
    </div>
  );
}

function LiveMap({
  order,
  rider,
}: {
  order: Order;
  rider: RiderLocation | null;
}) {
  const lat =
    rider?.latitude ??
    order.assignment?.rider?.locations?.[0]?.latitude ??
    order.deliveryLat ??
    order.restaurant?.latitude ??
    23.788;
  const lng =
    rider?.longitude ??
    order.assignment?.rider?.locations?.[0]?.longitude ??
    order.deliveryLng ??
    order.restaurant?.longitude ??
    90.405;
  const d = 0.008;
  const bbox = `${lng - d},${lat - d},${lng + d},${lat + d}`;

  return (
    <div className="mt-4 overflow-hidden rounded-[14px] border border-[var(--border-subtle)]">
      <div className="flex items-center gap-2 bg-[var(--surface)] px-4 py-2.5 text-sm font-semibold">
        <span className="h-2 w-2 animate-pulse rounded-full bg-[#3ddc84]" />
        {rider ? "Rider location — live" : "Following your rider"}
      </div>
      <iframe
        title="Live delivery tracking"
        className="h-[300px] w-full"
        loading="lazy"
        src={`https://www.openstreetmap.org/export/embed.html?bbox=${bbox}&layer=mapnik&marker=${lat},${lng}`}
      />
    </div>
  );
}

function InfoCard({
  icon: Icon,
  title,
  value,
  interactive,
}: {
  icon: typeof Clock;
  title: string;
  value: string;
  interactive?: boolean;
}) {
  return (
    <div
      className={`flex items-center gap-3 rounded-[12px] border border-[var(--border-subtle)] bg-[var(--surface)] p-4 ${
        interactive ? "transition-colors hover:border-[var(--brand)]" : ""
      }`}
    >
      <span className="grid h-10 w-10 flex-none place-items-center rounded-full bg-[color-mix(in_srgb,var(--brand)_10%,transparent)] text-[var(--brand)]">
        <Icon className="h-5 w-5" />
      </span>
      <div className="min-w-0">
        <p className="text-xs font-semibold text-[var(--foreground-mute)]">
          {title}
        </p>
        <p className="truncate text-sm font-bold">{value}</p>
      </div>
    </div>
  );
}

function Row({
  label,
  value,
  accent,
}: {
  label: string;
  value: string;
  accent?: boolean;
}) {
  return (
    <div className="flex items-center justify-between">
      <dt className="text-[var(--foreground-dim)]">{label}</dt>
      <dd
        className={`font-semibold tabular-nums ${accent ? "text-[var(--brand)]" : ""}`}
      >
        {value}
      </dd>
    </div>
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
