"use client";

import { useState } from "react";
import {
  Clock,
  MapPin,
  Phone,
  Receipt,
  User,
} from "lucide-react";

import {
  Sheet,
  SheetContent,
  SheetHeader,
  SheetTitle,
} from "@/components/ui/sheet";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Separator } from "@/components/ui/separator";
import { Textarea } from "@/components/ui/textarea";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Dialog,
  DialogContent,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Skeleton } from "@/components/ui/skeleton";
import { ErrorState } from "@/components/common/error-state";
import { Spinner } from "@/components/common/spinner";
import { DispatchPanel } from "@/components/orders/dispatch-panel";
import { orderStatusConfig } from "@/lib/order-status";
import {
  useAcceptOrder,
  useCancelOrder,
  useOrderDetail,
  useRejectOrder,
  useUpdateOrderStatus,
} from "@/lib/api/queries/orders";
import { formatCurrency, formatDateTime } from "@/lib/utils";
import type { Order, OrderStatus } from "@/types";

interface Props {
  orderId: string | null;
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

export function OrderDetailSheet({ orderId, open, onOpenChange }: Props) {
  const { data: order, isLoading, isError, refetch } = useOrderDetail(orderId);

  return (
    <Sheet open={open} onOpenChange={onOpenChange}>
      <SheetContent side="right" className="w-full sm:max-w-xl">
        {isLoading ? (
          <DetailSkeleton />
        ) : isError || !order ? (
          <div className="p-5">
            <ErrorState
              message="Couldn't load this order."
              onRetry={() => refetch()}
            />
          </div>
        ) : (
          <OrderDetailBody order={order} onClose={() => onOpenChange(false)} />
        )}
      </SheetContent>
    </Sheet>
  );
}

function DetailSkeleton() {
  return (
    <div className="space-y-4 p-5">
      <Skeleton className="h-7 w-40" />
      <Skeleton className="h-24 w-full" />
      <Skeleton className="h-40 w-full" />
      <Skeleton className="h-32 w-full" />
    </div>
  );
}

function OrderDetailBody({
  order,
  onClose,
}: {
  order: Order;
  onClose: () => void;
}) {
  const cfg = orderStatusConfig(order.status);
  return (
    <>
      <SheetHeader>
        <div className="flex items-center gap-3">
          <SheetTitle>#{order.orderNumber}</SheetTitle>
          <Badge variant={cfg.variant}>{cfg.label}</Badge>
        </div>
        <p className="text-muted-foreground text-sm">
          {order.orderType} · {formatDateTime(order.createdAt)}
        </p>
      </SheetHeader>

      <div className="scrollbar-thin flex-1 space-y-5 overflow-y-auto p-5">
        {/* Customer */}
        <section className="space-y-2">
          <SectionTitle icon={User}>Customer</SectionTitle>
          <div className="bg-muted/40 space-y-1.5 rounded-lg border p-3 text-sm">
            <p className="font-medium">{order.customerName || "Guest"}</p>
            {order.customerPhone && (
              <p className="text-muted-foreground flex items-center gap-1.5">
                <Phone className="size-3.5" /> {order.customerPhone}
              </p>
            )}
            {order.deliveryAddress && (
              <p className="text-muted-foreground flex items-start gap-1.5">
                <MapPin className="mt-0.5 size-3.5 shrink-0" />
                {order.deliveryAddress}
              </p>
            )}
          </div>
        </section>

        {/* Items */}
        <section className="space-y-2">
          <SectionTitle icon={Receipt}>
            Items ({order.items?.length ?? 0})
          </SectionTitle>
          <div className="space-y-2">
            {order.items?.map((item) => (
              <div key={item.id} className="flex items-start gap-3 text-sm">
                <span className="bg-muted flex size-6 shrink-0 items-center justify-center rounded text-xs font-semibold">
                  {item.quantity}
                </span>
                <div className="min-w-0 flex-1">
                  <p className="font-medium">{item.name}</p>
                  {item.addons && item.addons.length > 0 && (
                    <p className="text-muted-foreground text-xs">
                      {item.addons.map((a) => a.name).join(", ")}
                    </p>
                  )}
                  {item.notes && (
                    <p className="text-muted-foreground text-xs italic">
                      “{item.notes}”
                    </p>
                  )}
                </div>
                <span className="tabular-nums">
                  {formatCurrency(item.lineTotal)}
                </span>
              </div>
            ))}
          </div>
        </section>

        {/* Totals */}
        <section className="space-y-1.5 text-sm">
          <Row label="Subtotal" value={order.subtotal} />
          {order.discountAmount > 0 && (
            <Row label="Discount" value={-order.discountAmount} />
          )}
          <Row label="Tax" value={order.taxAmount} />
          {order.packagingFee > 0 && (
            <Row label="Packaging" value={order.packagingFee} />
          )}
          <Row label="Delivery fee" value={order.deliveryFee} />
          <Separator className="my-1" />
          <div className="flex justify-between font-semibold">
            <span>Total</span>
            <span className="tabular-nums">
              {formatCurrency(order.grandTotal)}
            </span>
          </div>
          <p className="text-muted-foreground pt-1 text-xs">
            {order.paymentMethod} · {order.paymentStatus}
          </p>
        </section>

        {/* Dispatch */}
        {DISPATCHABLE_STATUSES.includes(order.status) && (
          <section className="space-y-2">
            <SectionTitle icon={Clock}>Delivery</SectionTitle>
            <DispatchPanel order={order} />
          </section>
        )}

        {/* Timeline */}
        {order.statusHistory && order.statusHistory.length > 0 && (
          <section className="space-y-2">
            <SectionTitle icon={Clock}>Timeline</SectionTitle>
            <ol className="space-y-3">
              {order.statusHistory.map((h) => {
                const hc = orderStatusConfig(h.status);
                return (
                  <li key={h.id} className="flex gap-3 text-sm">
                    <div className="flex flex-col items-center">
                      <span className="bg-primary mt-1 size-2 rounded-full" />
                      <span className="bg-border w-px flex-1" />
                    </div>
                    <div className="pb-1">
                      <p className="font-medium">{hc.label}</p>
                      <p className="text-muted-foreground text-xs">
                        {formatDateTime(h.createdAt)}
                        {h.note ? ` · ${h.note}` : ""}
                      </p>
                    </div>
                  </li>
                );
              })}
            </ol>
          </section>
        )}
      </div>

      <OrderActions order={order} onDone={onClose} />
    </>
  );
}

const DISPATCHABLE_STATUSES: OrderStatus[] = [
  "READY_FOR_PICKUP",
  "PICKED_UP",
  "ON_THE_WAY",
];

const CANCELLABLE_STATUSES: OrderStatus[] = [
  "PLACED",
  "ACCEPTED",
  "PREPARING",
  "READY_FOR_PICKUP",
];

function OrderActions({
  order,
  onDone,
}: {
  order: Order;
  onDone: () => void;
}) {
  const accept = useAcceptOrder();
  const reject = useRejectOrder();
  const cancel = useCancelOrder();
  const updateStatus = useUpdateOrderStatus();

  const [acceptOpen, setAcceptOpen] = useState(false);
  const [rejectOpen, setRejectOpen] = useState(false);
  const [cancelOpen, setCancelOpen] = useState(false);
  const [prepMinutes, setPrepMinutes] = useState("15");
  const [reason, setReason] = useState("");

  const advance = (status: OrderStatus) =>
    updateStatus.mutate({ id: order.id, status });

  const busy =
    accept.isPending ||
    reject.isPending ||
    cancel.isPending ||
    updateStatus.isPending;

  const primary: React.ReactNode = (() => {
    switch (order.status) {
      case "PLACED":
        return (
          <Button
            className="flex-1"
            disabled={busy}
            onClick={() => setAcceptOpen(true)}
          >
            Accept order
          </Button>
        );
      case "ACCEPTED":
        return (
          <Button
            className="flex-1"
            disabled={busy}
            onClick={() => advance("PREPARING")}
          >
            {updateStatus.isPending && <Spinner />}
            Start preparing
          </Button>
        );
      case "PREPARING":
        return (
          <Button
            className="flex-1"
            disabled={busy}
            onClick={() => advance("READY_FOR_PICKUP")}
          >
            {updateStatus.isPending && <Spinner />}
            Mark ready for pickup
          </Button>
        );
      default:
        return null;
    }
  })();

  const canCancel = CANCELLABLE_STATUSES.includes(order.status);
  const showReject = order.status === "PLACED";

  if (!primary && !canCancel && !showReject) return null;

  return (
    <div className="flex gap-2 border-t p-5">
      {primary}
      {showReject && (
        <Button
          variant="outline"
          disabled={busy}
          onClick={() => setRejectOpen(true)}
        >
          Reject
        </Button>
      )}
      {canCancel && !showReject && (
        <Button
          variant="outline"
          className="text-destructive"
          disabled={busy}
          onClick={() => setCancelOpen(true)}
        >
          Cancel
        </Button>
      )}

      {/* Accept dialog (prep time) */}
      <Dialog open={acceptOpen} onOpenChange={setAcceptOpen}>
        <DialogContent className="max-w-sm">
          <DialogHeader>
            <DialogTitle>Accept order</DialogTitle>
          </DialogHeader>
          <div className="space-y-2">
            <Label htmlFor="prep">Estimated prep time (minutes)</Label>
            <Input
              id="prep"
              type="number"
              min={1}
              value={prepMinutes}
              onChange={(e) => setPrepMinutes(e.target.value)}
            />
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setAcceptOpen(false)}>
              Cancel
            </Button>
            <Button
              disabled={accept.isPending}
              onClick={() =>
                accept.mutate(
                  { id: order.id, prepMinutes: Number(prepMinutes) || undefined },
                  {
                    onSuccess: () => {
                      setAcceptOpen(false);
                      onDone();
                    },
                  }
                )
              }
            >
              {accept.isPending && <Spinner />}
              Accept
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Reject dialog */}
      <ReasonDialog
        open={rejectOpen}
        onOpenChange={setRejectOpen}
        title="Reject order"
        confirmLabel="Reject order"
        destructive
        value={reason}
        onChange={setReason}
        pending={reject.isPending}
        onConfirm={() =>
          reject.mutate(
            { id: order.id, note: reason || undefined },
            {
              onSuccess: () => {
                setRejectOpen(false);
                setReason("");
                onDone();
              },
            }
          )
        }
      />

      {/* Cancel dialog */}
      <ReasonDialog
        open={cancelOpen}
        onOpenChange={setCancelOpen}
        title="Cancel order"
        confirmLabel="Cancel order"
        destructive
        value={reason}
        onChange={setReason}
        pending={cancel.isPending}
        onConfirm={() =>
          cancel.mutate(
            { id: order.id, reason: reason || undefined },
            {
              onSuccess: () => {
                setCancelOpen(false);
                setReason("");
                onDone();
              },
            }
          )
        }
      />
    </div>
  );
}

function ReasonDialog({
  open,
  onOpenChange,
  title,
  confirmLabel,
  destructive,
  value,
  onChange,
  pending,
  onConfirm,
}: {
  open: boolean;
  onOpenChange: (v: boolean) => void;
  title: string;
  confirmLabel: string;
  destructive?: boolean;
  value: string;
  onChange: (v: string) => void;
  pending: boolean;
  onConfirm: () => void;
}) {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-sm">
        <DialogHeader>
          <DialogTitle>{title}</DialogTitle>
        </DialogHeader>
        <div className="space-y-2">
          <Label htmlFor="reason">Reason (optional)</Label>
          <Textarea
            id="reason"
            placeholder="Add a note for the record…"
            value={value}
            onChange={(e) => onChange(e.target.value)}
          />
        </div>
        <DialogFooter>
          <Button variant="outline" onClick={() => onOpenChange(false)}>
            Back
          </Button>
          <Button
            variant={destructive ? "destructive" : "default"}
            disabled={pending}
            onClick={onConfirm}
          >
            {pending && <Spinner />}
            {confirmLabel}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

function SectionTitle({
  icon: Icon,
  children,
}: {
  icon: React.ComponentType<{ className?: string }>;
  children: React.ReactNode;
}) {
  return (
    <p className="text-muted-foreground flex items-center gap-1.5 text-xs font-semibold uppercase tracking-wide">
      <Icon className="size-3.5" />
      {children}
    </p>
  );
}

function Row({ label, value }: { label: string; value: number }) {
  return (
    <div className="text-muted-foreground flex justify-between">
      <span>{label}</span>
      <span className="tabular-nums">{formatCurrency(value)}</span>
    </div>
  );
}
