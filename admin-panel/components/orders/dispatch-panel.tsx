"use client";

import { useState } from "react";
import { Bike, Star, Zap } from "lucide-react";

import { Button } from "@/components/ui/button";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Badge } from "@/components/ui/badge";
import { Spinner } from "@/components/common/spinner";
import {
  useAssignRider,
  useAutoAssign,
  useAvailableRiders,
  useForceUnassign,
} from "@/lib/api/queries/dispatch";
import type { Order } from "@/types";

export function DispatchPanel({ order }: { order: Order }) {
  const assignment = order.assignment;
  const isAssigned =
    !!assignment &&
    ["CREATED", "NOTIFIED", "ACCEPTED"].includes(assignment.status);

  const riders = useAvailableRiders(!isAssigned);
  const autoAssign = useAutoAssign();
  const assignRider = useAssignRider();
  const forceUnassign = useForceUnassign();
  const [selected, setSelected] = useState<string>("");

  const busy =
    autoAssign.isPending || assignRider.isPending || forceUnassign.isPending;

  if (isAssigned && assignment) {
    return (
      <div className="bg-muted/40 space-y-3 rounded-lg border p-4">
        <div className="flex items-center justify-between">
          <p className="text-sm font-medium">Rider</p>
          <Badge variant={assignment.status === "ACCEPTED" ? "success" : "info"}>
            {assignment.status === "ACCEPTED" ? "Accepted" : "Offered"}
          </Badge>
        </div>
        <div className="flex items-center gap-3">
          <div className="bg-primary/10 text-primary flex size-9 items-center justify-center rounded-full">
            <Bike className="size-4" />
          </div>
          <div>
            <p className="font-medium">
              {assignment.rider?.fullName || "Rider"}
            </p>
            <p className="text-muted-foreground text-xs">
              {assignment.rider?.phone || "—"}
            </p>
          </div>
        </div>
        <Button
          variant="outline"
          size="sm"
          className="w-full"
          disabled={busy}
          onClick={() =>
            forceUnassign.mutate({ orderId: order.id, reason: "Manual reassign" })
          }
        >
          {forceUnassign.isPending && <Spinner />}
          Unassign rider
        </Button>
      </div>
    );
  }

  return (
    <div className="space-y-3 rounded-lg border p-4">
      <p className="text-sm font-medium">Dispatch a rider</p>

      <Button
        className="w-full"
        disabled={busy}
        onClick={() => autoAssign.mutate(order.id)}
      >
        {autoAssign.isPending ? <Spinner /> : <Zap className="size-4" />}
        Auto-assign best rider
      </Button>

      <div className="flex items-center gap-2">
        <div className="bg-border h-px flex-1" />
        <span className="text-muted-foreground text-xs">or assign manually</span>
        <div className="bg-border h-px flex-1" />
      </div>

      <div className="flex gap-2">
        <Select value={selected} onValueChange={setSelected}>
          <SelectTrigger className="w-full" size="sm">
            <SelectValue
              placeholder={
                riders.isLoading
                  ? "Loading riders…"
                  : riders.data?.length
                    ? "Select a rider"
                    : "No riders online"
              }
            />
          </SelectTrigger>
          <SelectContent>
            {riders.data?.map((r) => (
              <SelectItem key={r.id} value={r.id}>
                <span className="flex items-center gap-2">
                  {r.fullName || "Rider"}
                  {r.ratingAvg != null && (
                    <span className="text-muted-foreground flex items-center gap-0.5 text-xs">
                      <Star className="size-3 fill-current" />
                      {r.ratingAvg.toFixed(1)}
                    </span>
                  )}
                </span>
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
        <Button
          size="sm"
          variant="secondary"
          disabled={!selected || busy}
          onClick={() =>
            assignRider.mutate({ orderId: order.id, riderId: selected })
          }
        >
          Assign
        </Button>
      </div>
    </div>
  );
}
