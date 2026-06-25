"use client";

import { useEffect, useState } from "react";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import {
  Card,
  CardContent,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Spinner } from "@/components/common/spinner";
import { useUpdateSettings } from "@/lib/api/queries/settings";
import type { RestaurantDetail } from "@/types";

export function BusinessForm({ restaurant }: { restaurant?: RestaurantDetail }) {
  const update = useUpdateSettings();
  const s = restaurant?.settings;

  const [taxRatePercent, setTax] = useState("");
  const [packagingFee, setPackaging] = useState("");
  const [currency, setCurrency] = useState("BDT");
  const [minOrderAmount, setMinOrder] = useState("");
  const [defaultPrepMinutes, setPrep] = useState("");
  const [autoAcceptOrders, setAutoAccept] = useState(false);
  const [showTestOrdersInKitchen, setShowTest] = useState(false);

  useEffect(() => {
    if (!s) return;
    setTax(s.taxRatePercent != null ? String(s.taxRatePercent) : "");
    setPackaging(s.packagingFee != null ? String(s.packagingFee) : "");
    setCurrency(s.currency ?? "BDT");
    setMinOrder(s.minOrderAmount != null ? String(s.minOrderAmount) : "");
    setPrep(s.defaultPrepMinutes != null ? String(s.defaultPrepMinutes) : "");
    setAutoAccept(s.autoAcceptOrders ?? false);
    setShowTest(s.showTestOrdersInKitchen ?? false);
  }, [s]);

  return (
    <Card>
      <CardHeader className="border-b">
        <CardTitle>Business settings</CardTitle>
        <CardDescription>
          Tax, fees, and order-handling defaults.
        </CardDescription>
      </CardHeader>
      <CardContent className="space-y-4 pt-6">
        <div className="grid gap-4 sm:grid-cols-2">
          <Field label="Tax rate (%)" value={taxRatePercent} onChange={setTax} />
          <Field label="Packaging fee (৳)" value={packagingFee} onChange={setPackaging} />
          <Field label="Min order (৳)" value={minOrderAmount} onChange={setMinOrder} />
          <Field
            label="Default prep (minutes)"
            value={defaultPrepMinutes}
            onChange={setPrep}
          />
          <div className="space-y-2">
            <Label htmlFor="currency">Currency</Label>
            <Input
              id="currency"
              value={currency}
              onChange={(e) => setCurrency(e.target.value)}
            />
          </div>
        </div>
        <Toggle
          label="Auto-accept orders"
          hint="Skip manual acceptance and start prep immediately."
          checked={autoAcceptOrders}
          onChange={setAutoAccept}
        />
        <Toggle
          label="Show test orders in kitchen"
          hint="Display test orders on the kitchen display."
          checked={showTestOrdersInKitchen}
          onChange={setShowTest}
        />
      </CardContent>
      <CardFooter className="border-t">
        <Button
          className="ml-auto"
          disabled={update.isPending}
          onClick={() =>
            update.mutate({
              taxRatePercent: num(taxRatePercent),
              packagingFee: num(packagingFee),
              currency: currency || undefined,
              minOrderAmount: num(minOrderAmount),
              defaultPrepMinutes: num(defaultPrepMinutes),
              autoAcceptOrders,
              showTestOrdersInKitchen,
            })
          }
        >
          {update.isPending && <Spinner />}
          Save settings
        </Button>
      </CardFooter>
    </Card>
  );
}

function num(v: string): number | undefined {
  if (v === "") return undefined;
  const n = Number(v);
  return Number.isNaN(n) ? undefined : n;
}

export function Field({
  label,
  value,
  onChange,
}: {
  label: string;
  value: string;
  onChange: (v: string) => void;
}) {
  return (
    <div className="space-y-2">
      <Label>{label}</Label>
      <Input
        type="number"
        min={0}
        value={value}
        onChange={(e) => onChange(e.target.value)}
      />
    </div>
  );
}

export function Toggle({
  label,
  hint,
  checked,
  onChange,
}: {
  label: string;
  hint: string;
  checked: boolean;
  onChange: (v: boolean) => void;
}) {
  return (
    <div className="flex items-center justify-between rounded-lg border p-3">
      <div>
        <p className="text-sm font-medium">{label}</p>
        <p className="text-muted-foreground text-xs">{hint}</p>
      </div>
      <Switch checked={checked} onCheckedChange={onChange} />
    </div>
  );
}
