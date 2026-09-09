"use client";

import { useEffect, useState } from "react";
import { MapPin, Pencil, Plus, Trash2 } from "lucide-react";

import {
  Dialog,
  DialogContent,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import { Badge } from "@/components/ui/badge";
import { Card } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { Spinner } from "@/components/common/spinner";
import { EmptyState } from "@/components/common/empty-state";
import { ErrorState } from "@/components/common/error-state";
import { ConfirmDialog } from "@/components/common/confirm-dialog";
import {
  useDeleteZone,
  useSaveZone,
  useZones,
} from "@/lib/api/queries/settings";
import type { DeliveryZone } from "@/types";

export function ZonesManager() {
  const { data, isLoading, isError, refetch } = useZones();
  const del = useDeleteZone();
  const [dialog, setDialog] = useState<{ open: boolean; zone?: DeliveryZone | null }>({
    open: false,
  });
  const [deleting, setDeleting] = useState<DeliveryZone | null>(null);

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <p className="text-muted-foreground text-sm">
          Areas you deliver to, defined by max distance.
        </p>
        <Button size="sm" onClick={() => setDialog({ open: true, zone: null })}>
          <Plus className="size-4" /> New zone
        </Button>
      </div>

      {isError ? (
        <ErrorState message="Couldn't load zones." onRetry={() => refetch()} />
      ) : isLoading ? (
        <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
          {Array.from({ length: 3 }).map((_, i) => (
            <Skeleton key={i} className="h-20 w-full rounded-xl" />
          ))}
        </div>
      ) : !data?.length ? (
        <EmptyState
          icon={MapPin}
          title="No delivery zones"
          description="Add a zone to define where you deliver."
        />
      ) : (
        <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
          {data.map((zone) => (
            <Card key={zone.id} className="flex-row items-center gap-3 p-4">
              <div className="bg-primary/10 text-primary flex size-9 items-center justify-center rounded-lg">
                <MapPin className="size-4" />
              </div>
              <div className="min-w-0 flex-1">
                <div className="flex items-center gap-2">
                  <p className="truncate font-medium">{zone.name}</p>
                  {!zone.isActive && <Badge variant="muted">Off</Badge>}
                </div>
                <p className="text-muted-foreground text-xs">
                  {zone.maxDistanceKm ? `Within ${zone.maxDistanceKm} km` : "No limit"}
                </p>
              </div>
              <Button
                variant="ghost"
                size="icon-sm"
                onClick={() => setDialog({ open: true, zone })}
                aria-label="Edit zone"
              >
                <Pencil className="size-4" />
              </Button>
              <Button
                variant="ghost"
                size="icon-sm"
                className="text-destructive"
                onClick={() => setDeleting(zone)}
                aria-label="Delete zone"
              >
                <Trash2 className="size-4" />
              </Button>
            </Card>
          ))}
        </div>
      )}

      <ZoneFormDialog
        open={dialog.open}
        onOpenChange={(o) => setDialog((s) => ({ ...s, open: o }))}
        zone={dialog.zone}
      />
      <ConfirmDialog
        open={!!deleting}
        onOpenChange={(o) => !o && setDeleting(null)}
        title="Delete zone?"
        description={deleting ? `"${deleting.name}" will be removed.` : ""}
        confirmLabel="Delete"
        destructive
        pending={del.isPending}
        onConfirm={() =>
          deleting && del.mutate(deleting.id, { onSuccess: () => setDeleting(null) })
        }
      />
    </div>
  );
}

function ZoneFormDialog({
  open,
  onOpenChange,
  zone,
}: {
  open: boolean;
  onOpenChange: (o: boolean) => void;
  zone?: DeliveryZone | null;
}) {
  const save = useSaveZone();
  const [name, setName] = useState("");
  const [maxDistanceKm, setMaxKm] = useState("");
  const [isActive, setIsActive] = useState(true);

  useEffect(() => {
    if (!open) return;
    setName(zone?.name ?? "");
    setMaxKm(zone?.maxDistanceKm != null ? String(zone.maxDistanceKm) : "");
    setIsActive(zone?.isActive ?? true);
  }, [open, zone]);

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-sm">
        <DialogHeader>
          <DialogTitle>{zone ? "Edit zone" : "New zone"}</DialogTitle>
        </DialogHeader>
        <div className="space-y-4">
          <div className="space-y-2">
            <Label htmlFor="zone-name">Name</Label>
            <Input
              id="zone-name"
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="e.g. Gulshan"
              autoFocus
            />
          </div>
          <div className="space-y-2">
            <Label htmlFor="zone-km">Max distance (km)</Label>
            <Input
              id="zone-km"
              type="number"
              min={0}
              value={maxDistanceKm}
              onChange={(e) => setMaxKm(e.target.value)}
              placeholder="Optional"
            />
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
            disabled={!name.trim() || save.isPending}
            onClick={() =>
              save.mutate(
                {
                  id: zone?.id,
                  name: name.trim(),
                  maxDistanceKm: maxDistanceKm ? Number(maxDistanceKm) : undefined,
                  isActive,
                },
                { onSuccess: () => onOpenChange(false) }
              )
            }
          >
            {save.isPending && <Spinner />}
            {zone ? "Save" : "Create"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
