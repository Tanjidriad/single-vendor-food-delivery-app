"use client";

import { useEffect, useState } from "react";

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
import { Spinner } from "@/components/common/spinner";
import { useSaveCategory } from "@/lib/api/queries/menu";
import type { MenuCategory } from "@/types";

interface Props {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  category?: MenuCategory | null;
}

export function CategoryFormDialog({ open, onOpenChange, category }: Props) {
  const save = useSaveCategory();
  const isEdit = !!category;

  const [name, setName] = useState("");
  const [sortOrder, setSortOrder] = useState("0");
  const [isActive, setIsActive] = useState(true);

  useEffect(() => {
    if (!open) return;
    setName(category?.name ?? "");
    setSortOrder(category ? String(category.sortOrder ?? 0) : "0");
    setIsActive(category?.isActive ?? true);
  }, [open, category]);

  const submit = () => {
    save.mutate(
      {
        id: category?.id,
        name: name.trim(),
        sortOrder: Number(sortOrder) || 0,
        isActive,
      },
      { onSuccess: () => onOpenChange(false) }
    );
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-sm">
        <DialogHeader>
          <DialogTitle>{isEdit ? "Edit category" : "New category"}</DialogTitle>
        </DialogHeader>
        <div className="space-y-4">
          <div className="space-y-2">
            <Label htmlFor="cat-name">Name</Label>
            <Input
              id="cat-name"
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="e.g. Starters"
              autoFocus
            />
          </div>
          <div className="space-y-2">
            <Label htmlFor="cat-sort">Sort order</Label>
            <Input
              id="cat-sort"
              type="number"
              value={sortOrder}
              onChange={(e) => setSortOrder(e.target.value)}
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
          <Button disabled={!name.trim() || save.isPending} onClick={submit}>
            {save.isPending && <Spinner />}
            {isEdit ? "Save" : "Create"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
