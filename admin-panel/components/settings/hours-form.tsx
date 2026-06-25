"use client";

import { useEffect, useState } from "react";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Switch } from "@/components/ui/switch";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Spinner } from "@/components/common/spinner";
import { useUpsertHours } from "@/lib/api/queries/settings";
import type { OperatingHour, RestaurantDetail } from "@/types";

const DAYS = [
  "Sunday",
  "Monday",
  "Tuesday",
  "Wednesday",
  "Thursday",
  "Friday",
  "Saturday",
];

export function HoursForm({ restaurant }: { restaurant?: RestaurantDetail }) {
  return (
    <Card>
      <CardHeader className="border-b">
        <CardTitle>Operating hours</CardTitle>
        <CardDescription>
          When customers can place orders, by day of week.
        </CardDescription>
      </CardHeader>
      <CardContent className="divide-y pt-2">
        {DAYS.map((label, day) => (
          <DayRow
            key={day}
            day={day}
            label={label}
            existing={restaurant?.operatingHours?.find((h) => h.dayOfWeek === day)}
          />
        ))}
      </CardContent>
    </Card>
  );
}

function DayRow({
  day,
  label,
  existing,
}: {
  day: number;
  label: string;
  existing?: OperatingHour;
}) {
  const save = useUpsertHours();
  const [openTime, setOpen] = useState("09:00");
  const [closeTime, setClose] = useState("22:00");
  const [isClosed, setClosed] = useState(false);

  useEffect(() => {
    if (!existing) return;
    setOpen(existing.openTime ?? "09:00");
    setClose(existing.closeTime ?? "22:00");
    setClosed(existing.isClosed ?? false);
  }, [existing]);

  return (
    <div className="flex flex-wrap items-center gap-3 py-3">
      <span className="w-24 text-sm font-medium">{label}</span>
      {isClosed ? (
        <span className="text-muted-foreground flex-1 text-sm">Closed</span>
      ) : (
        <div className="flex flex-1 items-center gap-2">
          <Input
            type="time"
            value={openTime}
            onChange={(e) => setOpen(e.target.value)}
            className="w-32"
          />
          <span className="text-muted-foreground text-sm">to</span>
          <Input
            type="time"
            value={closeTime}
            onChange={(e) => setClose(e.target.value)}
            className="w-32"
          />
        </div>
      )}
      <div className="flex items-center gap-2">
        <span className="text-muted-foreground text-xs">Closed</span>
        <Switch checked={isClosed} onCheckedChange={setClosed} />
      </div>
      <Button
        variant="outline"
        size="sm"
        disabled={save.isPending}
        onClick={() => save.mutate({ day, openTime, closeTime, isClosed })}
      >
        {save.isPending && save.variables?.day === day && <Spinner />}
        Save
      </Button>
    </div>
  );
}
