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
import { ImageUpload } from "@/components/common/image-upload";
import { useSaveBanner } from "@/lib/api/queries/promotions";
import type { Banner } from "@/types";

export function BannerFormDialog({
  open,
  onOpenChange,
  banner,
}: {
  open: boolean;
  onOpenChange: (o: boolean) => void;
  banner?: Banner | null;
}) {
  const save = useSaveBanner();
  const [title, setTitle] = useState("");
  const [imageUrl, setImageUrl] = useState<string | null>(null);
  const [linkUrl, setLinkUrl] = useState("");
  const [sortOrder, setSortOrder] = useState("0");
  const [isActive, setIsActive] = useState(true);

  useEffect(() => {
    if (!open) return;
    setTitle(banner?.title ?? "");
    setImageUrl(banner?.imageUrl ?? null);
    setLinkUrl(banner?.linkUrl ?? "");
    setSortOrder(banner ? String(banner.sortOrder ?? 0) : "0");
    setIsActive(banner?.isActive ?? true);
  }, [open, banner]);

  const valid = title.trim() && imageUrl;

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-h-[90vh] overflow-y-auto sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>{banner ? "Edit banner" : "New banner"}</DialogTitle>
        </DialogHeader>
        <div className="space-y-4">
          <div className="space-y-2">
            <Label>Banner image</Label>
            <ImageUpload value={imageUrl} onChange={setImageUrl} />
          </div>
          <div className="space-y-2">
            <Label htmlFor="banner-title">Title</Label>
            <Input
              id="banner-title"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="e.g. Weekend Feast 20% off"
            />
          </div>
          <div className="space-y-2">
            <Label htmlFor="banner-link">Link URL (optional)</Label>
            <Input
              id="banner-link"
              value={linkUrl}
              onChange={(e) => setLinkUrl(e.target.value)}
              placeholder="https://…"
            />
          </div>
          <div className="space-y-2">
            <Label htmlFor="banner-sort">Sort order</Label>
            <Input
              id="banner-sort"
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
          <Button
            disabled={!valid || save.isPending}
            onClick={() =>
              save.mutate(
                {
                  id: banner?.id,
                  title: title.trim(),
                  imageUrl,
                  linkUrl: linkUrl.trim() || undefined,
                  sortOrder: Number(sortOrder) || 0,
                  isActive,
                },
                { onSuccess: () => onOpenChange(false) }
              )
            }
          >
            {save.isPending && <Spinner />}
            {banner ? "Save" : "Create"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
