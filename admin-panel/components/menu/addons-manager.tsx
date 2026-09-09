"use client";

import { useEffect, useState } from "react";
import { Pencil, Plus, Trash2 } from "lucide-react";

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
import { ConfirmDialog } from "@/components/common/confirm-dialog";
import {
  useAddons,
  useDeleteAddon,
  useSaveAddon,
} from "@/lib/api/queries/menu";
import { formatCurrency } from "@/lib/utils";
import type { Addon } from "@/types";

export function AddonsManager() {
  const { data, isLoading } = useAddons();
  const del = useDeleteAddon();
  const [formOpen, setFormOpen] = useState(false);
  const [editing, setEditing] = useState<Addon | null>(null);
  const [deleting, setDeleting] = useState<Addon | null>(null);

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <p className="text-muted-foreground text-sm">
          Optional extras customers can add to items.
        </p>
        <Button
          size="sm"
          onClick={() => {
            setEditing(null);
            setFormOpen(true);
          }}
        >
          <Plus className="size-4" /> New add-on
        </Button>
      </div>

      {isLoading ? (
        <div className="grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-3">
          {Array.from({ length: 6 }).map((_, i) => (
            <Skeleton key={i} className="h-16 w-full rounded-xl" />
          ))}
        </div>
      ) : !data?.length ? (
        <EmptyState
          title="No add-ons yet"
          description="Create add-ons like extra cheese or a drink upgrade."
        />
      ) : (
        <div className="grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-3">
          {data.map((addon) => (
            <Card key={addon.id} className="flex-row items-center gap-3 p-3">
              <div className="min-w-0 flex-1">
                <div className="flex items-center gap-2">
                  <p className="truncate font-medium">{addon.name}</p>
                  {!addon.isActive && <Badge variant="muted">Off</Badge>}
                </div>
                <p className="text-muted-foreground text-sm tabular-nums">
                  +{formatCurrency(addon.price)}
                </p>
              </div>
              <Button
                variant="ghost"
                size="icon-sm"
                onClick={() => {
                  setEditing(addon);
                  setFormOpen(true);
                }}
                aria-label="Edit add-on"
              >
                <Pencil className="size-4" />
              </Button>
              <Button
                variant="ghost"
                size="icon-sm"
                className="text-destructive"
                onClick={() => setDeleting(addon)}
                aria-label="Delete add-on"
              >
                <Trash2 className="size-4" />
              </Button>
            </Card>
          ))}
        </div>
      )}

      <AddonFormDialog
        open={formOpen}
        onOpenChange={setFormOpen}
        addon={editing}
      />
      <ConfirmDialog
        open={!!deleting}
        onOpenChange={(o) => !o && setDeleting(null)}
        title="Delete add-on?"
        description={deleting ? `"${deleting.name}" will be removed.` : ""}
        confirmLabel="Delete"
        destructive
        pending={del.isPending}
        onConfirm={() =>
          deleting &&
          del.mutate(deleting.id, { onSuccess: () => setDeleting(null) })
        }
      />
    </div>
  );
}

function AddonFormDialog({
  open,
  onOpenChange,
  addon,
}: {
  open: boolean;
  onOpenChange: (o: boolean) => void;
  addon: Addon | null;
}) {
  const save = useSaveAddon();
  const [name, setName] = useState("");
  const [price, setPrice] = useState("");
  const [isActive, setIsActive] = useState(true);

  useEffect(() => {
    if (!open) return;
    setName(addon?.name ?? "");
    setPrice(addon ? String(addon.price) : "");
    setIsActive(addon?.isActive ?? true);
  }, [open, addon]);

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-sm">
        <DialogHeader>
          <DialogTitle>{addon ? "Edit add-on" : "New add-on"}</DialogTitle>
        </DialogHeader>
        <div className="space-y-4">
          <div className="space-y-2">
            <Label htmlFor="addon-name">Name</Label>
            <Input
              id="addon-name"
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="e.g. Extra cheese"
              autoFocus
            />
          </div>
          <div className="space-y-2">
            <Label htmlFor="addon-price">Price (৳)</Label>
            <Input
              id="addon-price"
              type="number"
              min={0}
              value={price}
              onChange={(e) => setPrice(e.target.value)}
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
            disabled={!name.trim() || price === "" || save.isPending}
            onClick={() =>
              save.mutate(
                {
                  id: addon?.id,
                  name: name.trim(),
                  price: Number(price),
                  isActive,
                },
                { onSuccess: () => onOpenChange(false) }
              )
            }
          >
            {save.isPending && <Spinner />}
            {addon ? "Save" : "Create"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
