"use client";

import { useEffect, useState } from "react";

import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Spinner } from "@/components/common/spinner";
import { Field } from "@/components/settings/business-form";
import { useUpdateDeliveryFee } from "@/lib/api/queries/settings";
import type { RestaurantDetail } from "@/types";

export function DeliveryForm({ restaurant }: { restaurant?: RestaurantDetail }) {
  const update = useUpdateDeliveryFee();
  const c = restaurant?.deliveryFeeConfig;

  const [baseFee, setBase] = useState("");
  const [perKmFee, setPerKm] = useState("");
  const [peakHourSurcharge, setPeak] = useState("");
  const [freeDeliveryThreshold, setFree] = useState("");
  const [maxDeliveryKm, setMaxKm] = useState("");

  useEffect(() => {
    if (!c) return;
    setBase(c.baseFee != null ? String(c.baseFee) : "");
    setPerKm(c.perKmFee != null ? String(c.perKmFee) : "");
    setPeak(c.peakHourSurcharge != null ? String(c.peakHourSurcharge) : "");
    setFree(c.freeDeliveryThreshold != null ? String(c.freeDeliveryThreshold) : "");
    setMaxKm(c.maxDeliveryKm != null ? String(c.maxDeliveryKm) : "");
  }, [c]);

  return (
    <Card>
      <CardHeader className="border-b">
        <CardTitle>Delivery pricing</CardTitle>
        <CardDescription>
          How delivery fees are calculated for customers.
        </CardDescription>
      </CardHeader>
      <CardContent className="grid gap-4 pt-6 sm:grid-cols-2">
        <Field label="Base fee (৳)" value={baseFee} onChange={setBase} />
        <Field label="Per-km fee (৳)" value={perKmFee} onChange={setPerKm} />
        <Field
          label="Peak-hour surcharge (৳)"
          value={peakHourSurcharge}
          onChange={setPeak}
        />
        <Field
          label="Free delivery over (৳)"
          value={freeDeliveryThreshold}
          onChange={setFree}
        />
        <Field label="Max delivery distance (km)" value={maxDeliveryKm} onChange={setMaxKm} />
      </CardContent>
      <CardFooter className="border-t">
        <Button
          className="ml-auto"
          disabled={update.isPending}
          onClick={() =>
            update.mutate({
              baseFee: num(baseFee),
              perKmFee: num(perKmFee),
              peakHourSurcharge: num(peakHourSurcharge),
              freeDeliveryThreshold: num(freeDeliveryThreshold),
              maxDeliveryKm: num(maxDeliveryKm),
            })
          }
        >
          {update.isPending && <Spinner />}
          Save pricing
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
