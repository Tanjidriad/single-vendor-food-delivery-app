"use client";

import { useEffect, useMemo, useRef, useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { toast } from "sonner";
import {
  ArrowLeft,
  Bike,
  Check,
  ChevronRight,
  Loader2,
  LocateFixed,
  MapPin,
  Minus,
  Plus,
  ShoppingBag,
  Smartphone,
  Tag,
  Trash2,
  Wallet,
} from "lucide-react";

import { Wordmark } from "@/components/brand";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { useAuth, useMe } from "@/lib/auth/use-auth";
import { useRestaurant } from "@/lib/api/queries/menu";
import { useAddresses } from "@/lib/api/queries/addresses";
import {
  geocodeAddress,
  reverseGeocode,
  useDeliveryQuote,
  useValidateCoupon,
} from "@/lib/api/queries/checkout";
import { usePlaceOrder } from "@/lib/api/queries/orders";
import { useInitiateOnlinePayment } from "@/lib/api/queries/payments";
import { useCartStore, lineTotal } from "@/store/cart-store";
import { formatTk } from "@/lib/utils";
import { placeholderFood } from "@/lib/placeholder-images";
import { calculateCheckoutTotals } from "@/lib/checkout-pricing";
import { ApiError } from "@/lib/api/client";
import { isTrustedPaymentUrl } from "@/lib/payments";
import type { Address, OrderType, PaymentMethod } from "@/types";

type Dropoff = { text: string; lat: number; lng: number } | null;

export default function CheckoutPage() {
  const router = useRouter();
  const { isAuthenticated, hydrated, user } = useAuth();
  useMe();

  const lines = useCartStore((s) => s.lines);
  const setQuantity = useCartStore((s) => s.setQuantity);
  const remove = useCartStore((s) => s.remove);
  const keyOf = useCartStore((s) => s.keyOf);
  const clear = useCartStore((s) => s.clear);
  const subtotal = useMemo(
    () => lines.reduce((s, l) => s + lineTotal(l), 0),
    [lines]
  );

  const {
    data: restaurant,
    isLoading: restaurantLoading,
    isError: restaurantError,
  } = useRestaurant();
  const restaurantId = restaurant?.id;
  const { data: addresses } = useAddresses();

  const [orderType, setOrderType] = useState<OrderType>("DELIVERY");
  const [paymentMethod, setPaymentMethod] = useState<PaymentMethod>("COD");
  // undefined = auto-select saved default; null = user chose a manual location.
  const [selectedAddrId, setSelectedAddrId] = useState<
    string | null | undefined
  >(undefined);
  const [manual, setManual] = useState<Dropoff>(null);
  const [manualText, setManualText] = useState("");
  const [locating, setLocating] = useState(false);

  const [couponCode, setCouponCode] = useState("");
  const [discount, setDiscount] = useState(0);
  const [appliedCoupon, setAppliedCoupon] = useState<string | null>(null);
  const [couponSubtotal, setCouponSubtotal] = useState<number | null>(null);

  const [name, setName] = useState<string | null>(null);
  const [phone, setPhone] = useState<string | null>(null);
  const [note, setNote] = useState("");

  const deliveryQuote = useDeliveryQuote();
  const validateCoupon = useValidateCoupon();
  const placeOrder = usePlaceOrder();
  const initiatePayment = useInitiateOnlinePayment();
  const idempotencyKey = useRef<string | null>(null);

  const [deliveryFee, setDeliveryFee] = useState(0);
  const [feeIssue, setFeeIssue] = useState<{
    key: string;
    message: string;
  } | null>(null);
  const lastQuoteKey = useRef<string>("");
  const quoteRequest = useRef(0);
  const [quotedKey, setQuotedKey] = useState<string | null>(null);

  const contactName = name ?? user?.fullName ?? "";
  const contactPhone = phone ?? user?.phone ?? "";
  const defaultAddress = addresses?.find((a) => a.isDefault) ?? addresses?.[0];
  const effectiveAddrId =
    selectedAddrId === undefined ? defaultAddress?.id ?? null : selectedAddrId;

  const dropoff: Dropoff = useMemo(() => {
    if (orderType !== "DELIVERY") return null;
    if (effectiveAddrId) {
      const a = addresses?.find((x) => x.id === effectiveAddrId);
      if (a) return { text: addressText(a), lat: a.latitude, lng: a.longitude };
    }
    return manual;
  }, [orderType, effectiveAddrId, addresses, manual]);

  // Fetch a delivery quote whenever the drop-off point or subtotal changes.
  useEffect(() => {
    if (orderType !== "DELIVERY" || !restaurantId || !dropoff || subtotal <= 0) {
      quoteRequest.current += 1;
      lastQuoteKey.current = "";
      return;
    }
    const key = `${dropoff.lat},${dropoff.lng},${subtotal}`;
    if (key === lastQuoteKey.current) return;
    lastQuoteKey.current = key;
    const requestId = ++quoteRequest.current;
    deliveryQuote.mutate(
      {
        restaurantId,
        deliveryLat: dropoff.lat,
        deliveryLng: dropoff.lng,
        subtotal,
      },
      {
        onSuccess: (q) => {
          if (requestId !== quoteRequest.current) return;
          setDeliveryFee(q.deliveryFee);
          setQuotedKey(key);
          setFeeIssue(null);
        },
        onError: (e) => {
          if (requestId !== quoteRequest.current) return;
          setDeliveryFee(0);
          setQuotedKey(null);
          setFeeIssue({
            key,
            message:
              e instanceof ApiError
                ? e.message
                : "Couldn't get a delivery quote.",
          });
        },
      }
    );
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [orderType, restaurantId, dropoff?.lat, dropoff?.lng, subtotal]);

  const minOrderAmount = restaurant?.settings?.minOrderAmount ?? 0;
  const belowMinimum = subtotal < minOrderAmount;
  const expectedQuoteKey =
    orderType === "DELIVERY" && dropoff
      ? `${dropoff.lat},${dropoff.lng},${subtotal}`
      : null;
  const feeError =
    feeIssue?.key === expectedQuoteKey ? feeIssue.message : null;
  const quoteReady =
    orderType === "PICKUP" ||
    (!!expectedQuoteKey && quotedKey === expectedQuoteKey && !feeError);
  const effectiveFee =
    orderType === "DELIVERY" && quoteReady ? deliveryFee : 0;
  const couponIsCurrent =
    !!appliedCoupon && couponSubtotal === subtotal;
  const effectiveDiscount = couponIsCurrent ? discount : 0;
  const { taxAmount, packagingFee, grandTotal } = calculateCheckoutTotals({
    subtotal,
    discount: effectiveDiscount,
    taxRatePercent: restaurant?.settings?.taxRatePercent ?? 0,
    packagingFee: restaurant?.settings?.packagingFee ?? 0,
    deliveryFee: effectiveFee,
  });
  const cannotPlace =
    placeOrder.isPending ||
    initiatePayment.isPending ||
    restaurantLoading ||
    restaurantError ||
    !restaurantId ||
    belowMinimum ||
    !quoteReady;

  function useCurrentLocation() {
    if (!navigator.geolocation) {
      toast.error("Location isn't available on this device.");
      return;
    }
    setLocating(true);
    navigator.geolocation.getCurrentPosition(
      async (pos) => {
        try {
          const { latitude, longitude } = pos.coords;
          const geo = await reverseGeocode(latitude, longitude);
          setSelectedAddrId(null);
          setManual({ text: geo.address, lat: latitude, lng: longitude });
          setManualText(geo.address);
        } catch {
          setManual({
            text: "Pinned location",
            lat: pos.coords.latitude,
            lng: pos.coords.longitude,
          });
        } finally {
          setLocating(false);
        }
      },
      () => {
        setLocating(false);
        toast.error("Couldn't get your location. Enter the address instead.");
      },
      { enableHighAccuracy: true, timeout: 10000 }
    );
  }

  async function findTypedAddress() {
    if (!manualText.trim()) return;
    try {
      const geo = await geocodeAddress(manualText.trim());
      setSelectedAddrId(null);
      setManual({ text: geo.address, lat: geo.latitude, lng: geo.longitude });
      setManualText(geo.address);
      toast.success("Address located.");
    } catch {
      toast.error("Couldn't find that address. Try adding more detail.");
    }
  }

  function applyCoupon() {
    if (!couponCode.trim() || !restaurantId) return;
    validateCoupon.mutate(
      { restaurantId, code: couponCode.trim().toUpperCase(), subtotal },
      {
        onSuccess: (res) => {
          setDiscount(res.discount);
          setAppliedCoupon(res.code);
          setCouponSubtotal(subtotal);
          toast.success(`Coupon ${res.code} applied.`);
        },
        onError: (e) =>
          toast.error(e instanceof ApiError ? e.message : "Invalid coupon."),
      }
    );
  }

  function removeCoupon() {
    setAppliedCoupon(null);
    setDiscount(0);
    setCouponSubtotal(null);
    setCouponCode("");
  }

  function changeQuantity(key: string, quantity: number) {
    removeCoupon();
    setQuantity(key, quantity);
  }

  function removeLine(key: string) {
    removeCoupon();
    remove(key);
  }

  function submit() {
    if (!restaurantId || restaurantError) {
      toast.error("The restaurant is unavailable right now. Please try again.");
      return;
    }
    if (belowMinimum) {
      toast.error(`Minimum order is ${formatTk(minOrderAmount)}.`);
      return;
    }
    if (!contactName.trim() || !contactPhone.trim()) {
      toast.error("Add your name and phone so the kitchen can reach you.");
      return;
    }
    if (orderType === "DELIVERY" && !dropoff) {
      toast.error("Choose a delivery address first.");
      return;
    }
    if (orderType === "DELIVERY" && !quoteReady) {
      toast.error(
        feeError || "Wait for us to confirm delivery availability and fee."
      );
      return;
    }
    placeOrder.mutate(
      {
        restaurantId,
        orderType,
        paymentMethod,
        items: lines.map((l) => ({
          menuItemId: l.itemId,
          quantity: l.quantity,
          addons: l.addons.map((a) => ({ addonId: a.id })),
        })),
        couponCode: couponIsCurrent ? appliedCoupon ?? undefined : undefined,
        customerName: contactName.trim(),
        customerPhone: contactPhone.trim(),
        deliveryAddress: dropoff?.text,
        deliveryLat: dropoff?.lat,
        deliveryLng: dropoff?.lng,
        deliveryNote: note.trim() || undefined,
        idempotencyKey:
          idempotencyKey.current ?? (idempotencyKey.current = createRequestId()),
      },
      {
        onSuccess: (order) => {
          clear();
          if (paymentMethod === "ONLINE") {
            initiatePayment.mutate(order.id, {
              onSuccess: (payment) => {
                if (!isTrustedPaymentUrl(payment.checkoutUrl)) {
                  toast.error("The payment gateway returned an unsafe URL.");
                  router.replace(`/orders/${order.id}?payment=retry`);
                  return;
                }
                window.location.assign(payment.checkoutUrl);
              },
              onError: (error) => {
                toast.error(
                  error instanceof ApiError
                    ? error.message
                    : "Couldn't open bKash. You can retry from the order page."
                );
                router.replace(`/orders/${order.id}?payment=retry`);
              },
            });
            return;
          }
          router.replace(`/orders/${order.id}`);
        },
        onError: (e) =>
          toast.error(
            e instanceof ApiError ? e.message : "Couldn't place the order."
          ),
      }
    );
  }

  // ── Guards ──
  if (hydrated && !isAuthenticated) {
    return (
      <Shell>
        <EmptyState
          icon={Wallet}
          title="Sign in to check out"
          body="You need an account to place and track your order."
          action={
            <Link href="/login?next=/checkout">
              <Button size="lg">Sign in to continue</Button>
            </Link>
          }
        />
      </Shell>
    );
  }

  if (lines.length === 0) {
    return (
      <Shell>
        <EmptyState
          icon={ShoppingBag}
          title="Your basket is empty"
          body="Add a few momos from the menu and they'll show up here."
          action={
            <Link href="/menu">
              <Button size="lg">Browse the menu</Button>
            </Link>
          }
        />
      </Shell>
    );
  }

  return (
    <Shell>
      <div className="mx-auto max-w-[1100px] px-4 py-6 pb-32 sm:px-6 lg:py-10 lg:pb-10">
        {/* --- BREADCRUMB --- */}
        <nav
          aria-label="Checkout steps"
          className="mb-6 flex items-center gap-2 text-[13px] font-semibold"
        >
          <Link
            href="/menu"
            className="text-[var(--brand)] hover:underline"
          >
            Cart
          </Link>
          <ChevronRight className="h-3.5 w-3.5 text-[var(--foreground-mute)]" />
          <span className="text-[var(--foreground)]">Details</span>
          <ChevronRight className="h-3.5 w-3.5 text-[var(--foreground-mute)]" />
          <span className="text-[var(--foreground-mute)]">Payment</span>
        </nav>

        <div className="grid gap-6 lg:grid-cols-[1.5fr_1fr] lg:items-start">
          {/* ── Left: details card ── */}
          <Card>
            {/* --- CONTACT + ADDRESS --- */}
            <SectionTitle>Delivery details</SectionTitle>

            <div className="mt-5 grid gap-4 sm:grid-cols-2">
              <FormField label="Full name" required>
                <Input
                  value={contactName}
                  onChange={(e) => setName(e.target.value)}
                  placeholder="Your name"
                />
              </FormField>
              <FormField label="Phone number" required>
                <Input
                  value={contactPhone}
                  onChange={(e) => setPhone(e.target.value)}
                  placeholder="01XXXXXXXXX"
                  type="tel"
                />
              </FormField>
            </div>

            {orderType === "DELIVERY" && (
              <>
                {/* Saved addresses */}
                {addresses && addresses.length > 0 && (
                  <div className="mt-4 space-y-2.5">
                    <p className="text-xs font-semibold text-[var(--foreground-dim)]">
                      Saved addresses
                    </p>
                    {addresses.map((a) => (
                      <button
                        key={a.id}
                        onClick={() => {
                          setSelectedAddrId(a.id);
                          setManual(null);
                        }}
                        className={`flex w-full items-start gap-3 rounded-[12px] border p-3.5 text-left transition-colors ${
                          effectiveAddrId === a.id
                            ? "border-[var(--brand)] bg-[color-mix(in_srgb,var(--brand)_6%,transparent)]"
                            : "border-[var(--border)] hover:border-[var(--foreground-mute)]"
                        }`}
                      >
                        <MapPin className="mt-0.5 h-4 w-4 flex-none text-[var(--brand)]" />
                        <div className="min-w-0">
                          <p className="text-sm font-semibold capitalize">
                            {a.label.toLowerCase()}
                          </p>
                          <p className="truncate text-[13px] text-[var(--foreground-dim)]">
                            {addressText(a)}
                          </p>
                        </div>
                        {effectiveAddrId === a.id && (
                          <Check className="ml-auto h-4 w-4 flex-none text-[var(--brand)]" />
                        )}
                      </button>
                    ))}
                  </div>
                )}

                {/* Manual / current location */}
                <div className="mt-4 grid gap-4 sm:grid-cols-2">
                  <FormField label="Delivery address" required>
                    <div className="flex flex-col gap-2 sm:flex-row">
                      <Input
                        value={manualText}
                        onChange={(e) => setManualText(e.target.value)}
                        placeholder="House, road, area"
                      />
                      <Button
                        type="button"
                        variant="light"
                        size="sm"
                        onClick={findTypedAddress}
                        className="h-11 flex-none"
                      >
                        Find
                      </Button>
                    </div>
                  </FormField>
                  <div className="flex items-end">
                    <button
                      onClick={useCurrentLocation}
                      disabled={locating}
                      className="inline-flex h-11 items-center gap-2 text-sm font-semibold text-[var(--brand)] disabled:opacity-60"
                    >
                      {locating ? (
                        <Loader2 className="h-4 w-4 animate-spin" />
                      ) : (
                        <LocateFixed className="h-4 w-4" />
                      )}
                      Use my current location
                    </button>
                  </div>
                </div>

                {manual && !effectiveAddrId && (
                  <div className="mt-3 flex items-start gap-3 rounded-[12px] border border-[var(--brand)] bg-[color-mix(in_srgb,var(--brand)_6%,transparent)] p-3.5">
                    <MapPin className="mt-0.5 h-4 w-4 flex-none text-[var(--brand)]" />
                    <p className="text-[13px] text-[var(--foreground-dim)]">
                      {manual.text}
                    </p>
                  </div>
                )}

                {feeError && (
                  <div
                    role="alert"
                    className="mt-3 rounded-[12px] border border-[color-mix(in_srgb,var(--brand)_28%,transparent)] bg-[color-mix(in_srgb,var(--brand)_6%,transparent)] p-3 text-sm text-[var(--brand)]"
                  >
                    {feeError} Change the address or try again before ordering.
                  </div>
                )}
              </>
            )}

            {/* Note / description */}
            <FormField
              label={orderType === "DELIVERY" ? "Delivery note" : "Order note"}
              className="mt-4"
            >
              <textarea
                value={note}
                onChange={(e) => setNote(e.target.value)}
                placeholder={
                  orderType === "DELIVERY"
                    ? "Gate code, landmark, or anything the rider should know"
                    : "Anything the kitchen should know"
                }
                rows={3}
                className="w-full resize-none rounded-[14px] border border-[var(--border)] bg-[var(--cream-100)] p-3.5 text-sm outline-none transition-colors focus-visible:border-[var(--brand)] focus-visible:ring-4 focus-visible:ring-[color-mix(in_srgb,var(--brand)_16%,transparent)]"
              />
            </FormField>

            {/* --- FULFILLMENT METHOD --- */}
            <SectionTitle className="mt-8">Fulfillment method</SectionTitle>
            <div className="mt-4 grid gap-3 sm:grid-cols-2">
              <MethodRow
                active={orderType === "DELIVERY"}
                icon={Bike}
                title="Delivery"
                body="To your address"
                trailing={
                  deliveryFee > 0 ? formatTk(deliveryFee) : "Quoted at address"
                }
                onClick={() => setOrderType("DELIVERY")}
              />
              <MethodRow
                active={orderType === "PICKUP"}
                icon={ShoppingBag}
                title="Pickup"
                body="Collect from Wasabi"
                trailing="Free"
                onClick={() => setOrderType("PICKUP")}
              />
            </div>

            {/* --- PAYMENT --- */}
            <SectionTitle className="mt-8">Payment</SectionTitle>
            <div className="mt-4 grid gap-3 sm:grid-cols-2">
              <MethodRow
                active={paymentMethod === "COD"}
                icon={Wallet}
                title={orderType === "PICKUP" ? "Pay at pickup" : "Cash on delivery"}
                body="Pay in cash when you receive it"
                trailing="Cash"
                onClick={() => setPaymentMethod("COD")}
              />
              <MethodRow
                active={paymentMethod === "ONLINE"}
                icon={Smartphone}
                title="Pay with bKash"
                body="Secure checkout after ordering"
                trailing="Online"
                onClick={() => setPaymentMethod("ONLINE")}
              />
            </div>
          </Card>

          {/* ── Right: cart summary ── */}
          <div className="lg:sticky lg:top-6 lg:self-start">
            <Card>
              <SectionTitle>Your cart</SectionTitle>

              {/* Items with thumbnails + qty badge */}
              <ul className="mt-5 space-y-4">
                {lines.map((l) => {
                  const k = keyOf(l);
                  const img = l.imageUrl || placeholderFood(l.itemId || l.name);
                  return (
                    <li key={k} className="flex items-center gap-3">
                      <div className="relative h-14 w-14 flex-none">
                        <div className="h-14 w-14 overflow-hidden rounded-[12px] border border-[var(--border-subtle)]">
                          <Image
                            src={img}
                            alt={l.name}
                            width={56}
                            height={56}
                            className="h-full w-full object-cover"
                          />
                        </div>
                        <span className="absolute -right-1.5 -top-1.5 grid h-5 min-w-5 place-items-center rounded-full bg-[var(--ink)] px-1 text-[11px] font-bold text-white">
                          {l.quantity}
                        </span>
                      </div>

                      <div className="min-w-0 flex-1">
                        <p className="truncate text-sm font-semibold leading-tight">
                          {l.name}
                        </p>
                        {l.addons.length > 0 && (
                          <p className="truncate text-xs text-[var(--foreground-mute)]">
                            {l.addons.map((a) => a.name).join(", ")}
                          </p>
                        )}
                        <div className="mt-1.5 flex items-center gap-1.5">
                          <button
                            aria-label="Decrease"
                            onClick={() => changeQuantity(k, l.quantity - 1)}
                            className="grid h-6 w-6 place-items-center rounded-full border border-[var(--border)] hover:bg-[var(--surface-sunken)]"
                          >
                            <Minus className="h-3 w-3" />
                          </button>
                          <span className="w-5 text-center text-xs font-bold tabular-nums">
                            {l.quantity}
                          </span>
                          <button
                            aria-label="Increase"
                            onClick={() => changeQuantity(k, l.quantity + 1)}
                            className="grid h-6 w-6 place-items-center rounded-full border border-[var(--border)] hover:bg-[var(--surface-sunken)]"
                          >
                            <Plus className="h-3 w-3" />
                          </button>
                          <button
                            aria-label="Remove"
                            onClick={() => removeLine(k)}
                            className="ml-1 grid h-6 w-6 place-items-center rounded-full text-[var(--foreground-mute)] hover:bg-[var(--surface-sunken)] hover:text-[var(--brand)]"
                          >
                            <Trash2 className="h-3 w-3" />
                          </button>
                        </div>
                      </div>

                      <span className="self-start text-sm font-bold tabular-nums">
                        {formatTk(lineTotal(l))}
                      </span>
                    </li>
                  );
                })}
              </ul>

              {/* Discount code */}
              <div className="mt-5 border-t border-[var(--border-subtle)] pt-4">
                {couponIsCurrent ? (
                  <div className="flex items-center justify-between rounded-[12px] bg-[color-mix(in_srgb,var(--brand)_8%,transparent)] px-3.5 py-2.5">
                    <span className="inline-flex items-center gap-2 text-sm font-semibold text-[var(--brand)]">
                      <Tag className="h-4 w-4" />
                      {appliedCoupon} applied
                    </span>
                    <button
                      onClick={removeCoupon}
                      className="text-xs font-semibold text-[var(--foreground-mute)] underline"
                    >
                      Remove
                    </button>
                  </div>
                ) : (
                  <div className="flex items-center gap-2 rounded-[14px] border border-[var(--border)] bg-[var(--cream-100)] p-1.5 pl-3.5">
                    <Tag className="h-4 w-4 flex-none text-[var(--foreground-mute)]" />
                    <input
                      value={couponCode}
                      onChange={(e) => setCouponCode(e.target.value)}
                      placeholder="Discount code"
                      className="min-w-0 flex-1 bg-transparent text-sm uppercase outline-none placeholder:normal-case placeholder:text-[var(--foreground-mute)]"
                    />
                    <button
                      type="button"
                      onClick={applyCoupon}
                      disabled={validateCoupon.isPending || !couponCode.trim()}
                      className="flex-none rounded-[10px] px-3 py-1.5 text-sm font-bold text-[var(--brand)] transition-colors hover:bg-[color-mix(in_srgb,var(--brand)_10%,transparent)] disabled:opacity-50"
                    >
                      {validateCoupon.isPending ? "…" : "Apply"}
                    </button>
                  </div>
                )}
              </div>

              {/* Totals */}
              <dl className="mt-5 space-y-2.5 text-sm">
                <Row label="Subtotal" value={formatTk(subtotal)} />
                {effectiveDiscount > 0 && (
                  <Row
                    label="Discount"
                    value={`− ${formatTk(effectiveDiscount)}`}
                    accent
                  />
                )}
                {taxAmount > 0 && (
                  <Row label="Tax" value={formatTk(taxAmount)} />
                )}
                {packagingFee > 0 && (
                  <Row label="Packaging" value={formatTk(packagingFee)} />
                )}
                {orderType === "DELIVERY" && (
                  <Row
                    label="Delivery fee"
                    value={
                      deliveryQuote.isPending
                        ? "…"
                        : dropoff
                          ? deliveryFee === 0
                            ? "Free"
                            : formatTk(deliveryFee)
                          : "—"
                    }
                  />
                )}
              </dl>

              {belowMinimum && (
                <p
                  role="alert"
                  className="mt-3 text-sm font-semibold text-[var(--brand)]"
                >
                  Add {formatTk(minOrderAmount - subtotal)} more to reach the
                  minimum order.
                </p>
              )}

              <div className="mt-4 flex items-center justify-between border-t border-[var(--border-subtle)] pt-4">
                <dt className="font-display text-base font-black">Total</dt>
                <dd className="font-display text-xl font-black tabular-nums">
                  {formatTk(grandTotal)}
                </dd>
              </div>

              <Button
                size="lg"
                className="mt-5 hidden w-full lg:inline-flex"
                onClick={submit}
                disabled={cannotPlace}
              >
                {placeOrder.isPending || initiatePayment.isPending ? (
                  <>
                    <Loader2 className="h-5 w-5 animate-spin" />
                    {initiatePayment.isPending ? "Opening bKash…" : "Placing order…"}
                  </>
                ) : (
                  <>Continue &amp; place order</>
                )}
              </Button>
              <p className="mt-3 text-center text-xs text-[var(--foreground-mute)]">
                You&apos;ll be able to track your order live after placing it.
              </p>
            </Card>
          </div>
        </div>
      </div>

      <div className="fixed inset-x-0 bottom-0 z-[var(--z-sticky)] border-t border-[var(--border-subtle)] bg-[color-mix(in_srgb,var(--surface)_96%,transparent)] px-4 pt-3 pb-[calc(0.75rem+env(safe-area-inset-bottom))] shadow-[0_-10px_30px_rgba(32,24,16,0.10)] backdrop-blur-xl lg:hidden">
        <div className="mx-auto flex max-w-[1100px] items-center gap-4">
          <div className="min-w-0 flex-1">
            <p className="text-[11px] font-semibold uppercase tracking-[0.12em] text-[var(--foreground-mute)]">
              Total
            </p>
            <p className="truncate font-display text-xl font-black tabular-nums">
              {formatTk(grandTotal)}
            </p>
          </div>
          <Button
            size="lg"
            className="h-12 min-w-[178px] flex-none"
            onClick={submit}
            disabled={cannotPlace}
          >
            {placeOrder.isPending || initiatePayment.isPending ? (
              <>
                <Loader2 className="h-5 w-5 animate-spin" />
                {initiatePayment.isPending ? "Opening bKash…" : "Placing…"}
              </>
            ) : (
              "Place order"
            )}
          </Button>
        </div>
      </div>
    </Shell>
  );
}

// ── Layout + primitives ──

function Shell({ children }: { children: React.ReactNode }) {
  return (
    <div className="wasabi-app-shell min-h-dvh bg-[var(--menu-rice)]">
      <header className="sticky top-0 z-[var(--z-sticky)] border-b-4 border-[var(--menu-red)] bg-[var(--menu-ink)] text-white">
        <div className="mx-auto flex h-16 max-w-[1100px] items-center gap-4 px-4 sm:px-6">
          <Link
            href="/menu"
            aria-label="Back to menu"
            className="grid h-10 w-10 place-items-center border border-white/20 transition-colors hover:bg-[var(--menu-red)]"
          >
            <ArrowLeft className="h-[18px] w-[18px]" />
          </Link>
          <h1 className="font-street text-lg">Counter checkout</h1>
          <div className="ml-auto">
            <Wordmark className="[&_span]:!text-white" />
          </div>
        </div>
      </header>
      {children}
    </div>
  );
}

function Card({ children }: { children: React.ReactNode }) {
  return (
    <div className="border-2 border-[var(--menu-ink)] bg-[var(--menu-rice)] p-5 sm:p-7">
      {children}
    </div>
  );
}

function SectionTitle({
  children,
  className,
}: {
  children: React.ReactNode;
  className?: string;
}) {
  return (
    <h2
      className={`font-street border-b-2 border-[var(--menu-red)] pb-3 text-xl ${className ?? ""}`}
    >
      {children}
    </h2>
  );
}

function FormField({
  label,
  required,
  className,
  children,
}: {
  label: string;
  required?: boolean;
  className?: string;
  children: React.ReactNode;
}) {
  return (
    <div className={className}>
      <label className="mb-1.5 block text-xs font-semibold text-[var(--foreground-dim)]">
        {label}
        {required && <span className="text-[var(--brand)]">*</span>}
      </label>
      {children}
    </div>
  );
}

function MethodRow({
  active,
  icon: Icon,
  title,
  body,
  trailing,
  onClick,
}: {
  active: boolean;
  icon: typeof Bike;
  title: string;
  body: string;
  trailing: string;
  onClick: () => void;
}) {
  return (
    <button
      onClick={onClick}
      aria-pressed={active}
      className={`flex items-center gap-3 rounded-[14px] border p-4 text-left transition-colors ${
        active
          ? "border-[var(--brand)] bg-[color-mix(in_srgb,var(--brand)_6%,transparent)]"
          : "border-[var(--border)] hover:border-[var(--foreground-mute)]"
      }`}
    >
      <span
        className={`grid h-6 w-6 flex-none place-items-center rounded-full border-2 ${
          active ? "border-[var(--brand)]" : "border-[var(--border)]"
        }`}
      >
        {active && <span className="h-2.5 w-2.5 rounded-full bg-[var(--brand)]" />}
      </span>
      <Icon
        className={`h-5 w-5 flex-none ${active ? "text-[var(--brand)]" : "text-[var(--foreground-dim)]"}`}
      />
      <div className="min-w-0">
        <p className="text-sm font-bold leading-tight">{title}</p>
        <p className="truncate text-xs text-[var(--foreground-dim)]">{body}</p>
      </div>
      <span className="ml-auto flex-none text-sm font-bold tabular-nums">
        {trailing}
      </span>
    </button>
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

function EmptyState({
  icon: Icon,
  title,
  body,
  action,
}: {
  icon: typeof ShoppingBag;
  title: string;
  body: string;
  action: React.ReactNode;
}) {
  return (
    <div className="mx-auto flex max-w-md flex-col items-center px-4 py-24 text-center">
      <span className="grid h-16 w-16 place-items-center rounded-full bg-[var(--surface-sunken)] text-[var(--foreground-dim)]">
        <Icon className="h-7 w-7" />
      </span>
      <h1 className="mt-5 font-display text-2xl font-black">{title}</h1>
      <p className="mt-2 text-sm text-[var(--foreground-dim)]">{body}</p>
      <div className="mt-6">{action}</div>
    </div>
  );
}

function addressText(a: Address): string {
  return [a.line1, a.line2, a.city].filter(Boolean).join(", ");
}

function createRequestId(): string {
  return crypto.randomUUID();
}
