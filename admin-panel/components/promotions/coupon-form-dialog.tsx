"use client";

import { useEffect, useState } from "react";

import {
  Dialog,
  DialogContent,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import { Spinner } from "@/components/common/spinner";
import { useSaveCoupon } from "@/lib/api/queries/promotions";
import type { Coupon } from "@/types";

export function CouponFormDialog({
  open,
  onOpenChange,
  coupon,
}: {
  open: boolean;
  onOpenChange: (o: boolean) => void;
  coupon?: Coupon | null;
}) {
  const save = useSaveCoupon();
  const [code, setCode] = useState("");
  const [discountType, setDiscountType] = useState<"PERCENT" | "FLAT">("PERCENT");
  const [discountValue, setDiscountValue] = useState("");
  const [minOrderAmount, setMinOrderAmount] = useState("");
  const [maxUses, setMaxUses] = useState("");
  const [endsAt, setEndsAt] = useState("");
  const [isActive, setIsActive] = useState(true);
  const [targeting, setTargeting] = useState<"EVERYONE" | "NEW" | "SPECIFIC">(
    "EVERYONE"
  );
  const [targetIdentifier, setTargetIdentifier] = useState("");
  const [perUserLimit, setPerUserLimit] = useState("");

  useEffect(() => {
    if (!open) return;
    setCode(coupon?.code ?? "");
    setDiscountType(coupon?.discountType ?? "PERCENT");
    setDiscountValue(coupon ? String(coupon.discountValue) : "");
    setMinOrderAmount(coupon?.minOrderAmount ? String(coupon.minOrderAmount) : "");
    setMaxUses(coupon?.maxUses ? String(coupon.maxUses) : "");
    setEndsAt(coupon?.endsAt ? coupon.endsAt.slice(0, 10) : "");
    setIsActive(coupon?.isActive ?? true);
    setPerUserLimit(coupon?.perUserLimit ? String(coupon.perUserLimit) : "");
    if (coupon?.targetUserId) {
      setTargeting("SPECIFIC");
      setTargetIdentifier(
        coupon.targetCustomer?.email || coupon.targetCustomer?.phone || ""
      );
    } else if (coupon?.newCustomersOnly) {
      setTargeting("NEW");
      setTargetIdentifier("");
    } else {
      setTargeting("EVERYONE");
      setTargetIdentifier("");
    }
  }, [open, coupon]);

  const valid =
    code.trim() &&
    discountValue !== "" &&
    (targeting !== "SPECIFIC" || targetIdentifier.trim() !== "");

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-h-[90vh] overflow-y-auto sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>{coupon ? "Edit coupon" : "New coupon"}</DialogTitle>
        </DialogHeader>
        <div className="space-y-4">
          <div className="space-y-2">
            <Label htmlFor="code">Code</Label>
            <Input
              id="code"
              value={code}
              onChange={(e) => setCode(e.target.value.toUpperCase())}
              placeholder="SAVE20"
              className="uppercase"
            />
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div className="space-y-2">
              <Label>Discount type</Label>
              <Select
                value={discountType}
                onValueChange={(v) => setDiscountType(v as "PERCENT" | "FLAT")}
              >
                <SelectTrigger className="w-full">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="PERCENT">Percentage (%)</SelectItem>
                  <SelectItem value="FLAT">Flat amount (৳)</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-2">
              <Label htmlFor="value">
                Value {discountType === "PERCENT" ? "(%)" : "(৳)"}
              </Label>
              <Input
                id="value"
                type="number"
                min={0}
                value={discountValue}
                onChange={(e) => setDiscountValue(e.target.value)}
              />
            </div>
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div className="space-y-2">
              <Label htmlFor="min">Min order (৳)</Label>
              <Input
                id="min"
                type="number"
                min={0}
                value={minOrderAmount}
                onChange={(e) => setMinOrderAmount(e.target.value)}
                placeholder="Optional"
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="max">Max uses</Label>
              <Input
                id="max"
                type="number"
                min={1}
                value={maxUses}
                onChange={(e) => setMaxUses(e.target.value)}
                placeholder="Unlimited"
              />
            </div>
          </div>
          <div className="space-y-2">
            <Label htmlFor="ends">Expires on</Label>
            <Input
              id="ends"
              type="date"
              value={endsAt}
              onChange={(e) => setEndsAt(e.target.value)}
            />
          </div>

          {/* Targeting */}
          <div className="space-y-3 rounded-lg border p-3">
            <div className="space-y-2">
              <Label>Who can use this?</Label>
              <Select
                value={targeting}
                onValueChange={(v) =>
                  setTargeting(v as "EVERYONE" | "NEW" | "SPECIFIC")
                }
              >
                <SelectTrigger className="w-full">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="EVERYONE">Everyone</SelectItem>
                  <SelectItem value="NEW">
                    New customers only (first order)
                  </SelectItem>
                  <SelectItem value="SPECIFIC">A specific customer</SelectItem>
                </SelectContent>
              </Select>
            </div>
            {targeting === "SPECIFIC" && (
              <div className="space-y-2">
                <Label htmlFor="target">Customer email or phone</Label>
                <Input
                  id="target"
                  value={targetIdentifier}
                  onChange={(e) => setTargetIdentifier(e.target.value)}
                  placeholder="customer@email.com or +8801…"
                />
                <p className="text-muted-foreground text-xs">
                  Only this customer will be able to redeem the code.
                </p>
              </div>
            )}
            <div className="space-y-2">
              <Label htmlFor="peruser">Max uses per customer</Label>
              <Input
                id="peruser"
                type="number"
                min={1}
                value={perUserLimit}
                onChange={(e) => setPerUserLimit(e.target.value)}
                placeholder="Unlimited"
              />
            </div>
          </div>

          <div className="flex items-center justify-between rounded-lg border p-3">
            <p className="text-sm font-medium">Active</p>
            <Switch checked={isActive} onCheckedChange={setIsActive} />
          </div>
        </div>
        <DialogFooter>
          <Button variant="outline" onClick={() => onOpenChange(false)}>
            Cancel
          </Button>
          <Button
            disabled={!valid || save.isPending}
            onClick={() =>
              save.mutate(
                {
                  id: coupon?.id,
                  code: code.trim().toUpperCase(),
                  discountType,
                  discountValue: Number(discountValue),
                  minOrderAmount: minOrderAmount ? Number(minOrderAmount) : undefined,
                  maxUses: maxUses ? Number(maxUses) : undefined,
                  endsAt: endsAt ? new Date(endsAt).toISOString() : undefined,
                  isActive,
                  perUserLimit: perUserLimit ? Number(perUserLimit) : undefined,
                  newCustomersOnly: targeting === "NEW",
                  targetCustomerIdentifier:
                    targeting === "SPECIFIC" ? targetIdentifier.trim() : "",
                },
                { onSuccess: () => onOpenChange(false) }
              )
            }
          >
            {save.isPending && <Spinner />}
            {coupon ? "Save" : "Create"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
