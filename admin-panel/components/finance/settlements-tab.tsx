"use client";

import { useEffect, useState } from "react";
import { Banknote, CheckCircle2 } from "lucide-react";

import {
  Dialog,
  DialogContent,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Skeleton } from "@/components/ui/skeleton";
import { Spinner } from "@/components/common/spinner";
import { EmptyState } from "@/components/common/empty-state";
import { ErrorState } from "@/components/common/error-state";
import { usePendingCod, useSettleCod } from "@/lib/api/queries/finance";
import { formatCurrency, formatDate } from "@/lib/utils";
import type { CodSettlement } from "@/types";

export function SettlementsTab() {
  const { data, isLoading, isError, refetch } = usePendingCod();
  const [active, setActive] = useState<CodSettlement | null>(null);

  const totalPending =
    data?.reduce(
      (sum, s) =>
        sum + (s.codCollectedAmount ?? 0) - (s.deliveryFeeKept ?? 0),
      0,
    ) ?? 0;

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <p className="text-muted-foreground text-sm">
          Cash-on-delivery food revenue awaiting remittance from riders.
        </p>
        {!isLoading && data && data.length > 0 && (
          <span className="text-sm">
            <span className="text-muted-foreground">Pending: </span>
            <span className="font-semibold tabular-nums">
              {formatCurrency(totalPending)}
            </span>
          </span>
        )}
      </div>

      {isError ? (
        <ErrorState message="Couldn't load settlements." onRetry={() => refetch()} />
      ) : isLoading ? (
        <div className="space-y-3">
          {Array.from({ length: 3 }).map((_, i) => (
            <Skeleton key={i} className="h-20 w-full rounded-xl" />
          ))}
        </div>
      ) : !data?.length ? (
        <EmptyState
          icon={CheckCircle2}
          title="All settled up"
          description="No pending COD remittances right now."
        />
      ) : (
        <div className="space-y-3">
          {data.map((s) => (
            <Card key={s.id} className="flex-row items-center gap-4 p-4">
              <div className="bg-warning/15 text-warning-foreground dark:text-warning flex size-10 items-center justify-center rounded-lg">
                <Banknote className="size-5" />
              </div>
              <div className="min-w-0 flex-1">
                <p className="font-medium">#{s.order.orderNumber}</p>
                <p className="text-muted-foreground text-xs">
                  {s.rider?.fullName || "Rider"} ·{" "}
                  {s.order.deliveredAt ? formatDate(s.order.deliveredAt) : "—"}
                </p>
              </div>
              <div className="text-right">
                <p className="text-muted-foreground text-xs">To remit</p>
                <p className="font-semibold tabular-nums">
                  {formatCurrency((s.codCollectedAmount ?? 0) - (s.deliveryFeeKept ?? 0))}
                </p>
              </div>
              <Button size="sm" onClick={() => setActive(s)}>
                Settle
              </Button>
            </Card>
          ))}
        </div>
      )}

      <SettleDialog settlement={active} onClose={() => setActive(null)} />
    </div>
  );
}

function SettleDialog({
  settlement,
  onClose,
}: {
  settlement: CodSettlement | null;
  onClose: () => void;
}) {
  const settle = useSettleCod();
  const [amount, setAmount] = useState("");
  const [note, setNote] = useState("");

  useEffect(() => {
    if (!settlement) return;
    const expected =
      (settlement.codCollectedAmount ?? 0) - (settlement.deliveryFeeKept ?? 0);
    setAmount(expected > 0 ? String(expected) : "");
    setNote("");
  }, [settlement]);

  return (
    <Dialog open={!!settlement} onOpenChange={(o) => !o && onClose()}>
      <DialogContent className="max-w-sm">
        <DialogHeader>
          <DialogTitle>Settle COD remittance</DialogTitle>
        </DialogHeader>
        <div className="space-y-4">
          <p className="text-muted-foreground text-sm">
            Order #{settlement?.order.orderNumber} ·{" "}
            {settlement?.rider?.fullName || "Rider"}
          </p>
          <div className="space-y-2">
            <Label htmlFor="amount">Amount remitted (৳)</Label>
            <Input
              id="amount"
              type="number"
              min={0}
              value={amount}
              onChange={(e) => setAmount(e.target.value)}
            />
          </div>
          <div className="space-y-2">
            <Label htmlFor="note">Note (optional)</Label>
            <Textarea
              id="note"
              value={note}
              onChange={(e) => setNote(e.target.value)}
            />
          </div>
        </div>
        <DialogFooter>
          <Button variant="outline" onClick={onClose}>
            Cancel
          </Button>
          <Button
            disabled={!settlement || settle.isPending}
            onClick={() =>
              settlement &&
              settle.mutate(
                {
                  orderId: settlement.orderId,
                  foodAmountRemitted: amount ? Number(amount) : undefined,
                  note: note || undefined,
                },
                { onSuccess: onClose }
              )
            }
          >
            {settle.isPending && <Spinner />}
            Confirm settlement
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
