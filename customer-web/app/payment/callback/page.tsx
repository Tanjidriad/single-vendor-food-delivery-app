"use client";

import { Suspense, useEffect, useState } from "react";
import Link from "next/link";
import { useSearchParams } from "next/navigation";
import { CheckCircle2, Loader2, XCircle } from "lucide-react";

import { Wordmark } from "@/components/brand";
import { Button } from "@/components/ui/button";
import { api, ApiError } from "@/lib/api/client";
import { endpoints } from "@/lib/api/endpoints";
import type { PaymentExecution } from "@/types";

export default function PaymentCallbackPage() {
  return (
    <Suspense fallback={<PaymentState state="checking" />}>
      <PaymentCallback />
    </Suspense>
  );
}

function PaymentCallback() {
  const params = useSearchParams();
  const [confirmation, setConfirmation] = useState<
    { state: "checking" | "success" | "failed"; message?: string }
  >({ state: "checking" });
  const orderId = params.get("orderId") ?? "";
  const paymentId = params.get("paymentID") ?? params.get("paymentId") ?? "";
  const gatewayStatus = (params.get("status") ?? "").toLowerCase();
  const gatewaySucceeded = gatewayStatus === "success";

  useEffect(() => {
    if (!gatewaySucceeded || !orderId || !paymentId) return;
    let active = true;
    api
      .post<PaymentExecution>(endpoints.payments.execute(orderId), { paymentId })
      .then(() => {
        if (active) setConfirmation({ state: "success" });
      })
      .catch((error: unknown) => {
        if (!active) return;
        setConfirmation({
          state: "failed",
          message:
            error instanceof ApiError
              ? error.message
              : "Check your order before trying again.",
        });
      });
    return () => {
      active = false;
    };
  }, [gatewaySucceeded, orderId, paymentId]);

  if (!orderId || (gatewaySucceeded && !paymentId)) {
    return (
      <PaymentState
        state="failed"
        title="Payment details are incomplete"
        body="Return to your orders and retry the payment. You have not been charged by this page."
      />
    );
  }

  if (!gatewaySucceeded) {
    return (
      <PaymentState
        state="failed"
        title={gatewayStatus === "cancel" ? "Payment cancelled" : "Payment wasn't completed"}
        body="Your order is saved. You can safely retry bKash from the order page."
        orderId={orderId}
      />
    );
  }

  if (confirmation.state === "checking") {
    return <PaymentState state="checking" />;
  }

  if (confirmation.state === "failed") {
    return (
      <PaymentState
        state="failed"
        title="We couldn't confirm the payment"
        body={confirmation.message}
        orderId={orderId}
      />
    );
  }

  return <PaymentState state="success" orderId={orderId} />;
}

function PaymentState({
  state,
  title,
  body,
  orderId,
}: {
  state: "checking" | "success" | "failed";
  title?: string;
  body?: string;
  orderId?: string;
}) {
  return (
    <main className="wasabi-app-shell grid min-h-dvh place-items-center bg-[var(--menu-rice)] px-4 py-10">
      <div className="w-full max-w-md border-2 border-[var(--menu-ink)] bg-[var(--menu-rice)] p-6 text-center sm:p-8">
        <Wordmark className="mx-auto justify-center" />
        <span
          className={`mx-auto mt-8 grid h-16 w-16 place-items-center rounded-full ${
            state === "success"
              ? "bg-emerald-50 text-emerald-700"
              : state === "failed"
                ? "bg-red-50 text-red-700"
                : "bg-[var(--surface-sunken)] text-[var(--brand)]"
          }`}
        >
          {state === "checking" ? (
            <Loader2 className="h-7 w-7 animate-spin" />
          ) : state === "success" ? (
            <CheckCircle2 className="h-8 w-8" />
          ) : (
            <XCircle className="h-8 w-8" />
          )}
        </span>
        <h1 className="font-street mt-5 text-3xl">
          {title ??
            (state === "checking"
              ? "Confirming your payment"
              : state === "success"
                ? "Payment confirmed"
                : "Payment not completed")}
        </h1>
        <p className="mt-2 text-sm leading-6 text-[var(--foreground-dim)]">
          {body ??
            (state === "checking"
              ? "Keep this page open for a moment."
              : "Your order is paid and has been sent to the kitchen.")}
        </p>
        {state !== "checking" && (
          <div className="mt-7 grid gap-3">
            {orderId && (
              <Button asChild size="lg">
                <Link href={`/orders/${orderId}`}>View order</Link>
              </Button>
            )}
            <Button asChild size="lg" variant="light">
              <Link href="/orders">All orders</Link>
            </Button>
          </div>
        )}
      </div>
    </main>
  );
}
