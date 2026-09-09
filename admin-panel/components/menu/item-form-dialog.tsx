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
import { Textarea } from "@/components/ui/textarea";
import { Switch } from "@/components/ui/switch";
import { Spinner } from "@/components/common/spinner";
import { ImageUpload } from "@/components/common/image-upload";
import { useSaveItem } from "@/lib/api/queries/menu";
import type { MenuCategory, MenuItem } from "@/types";

interface Props {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  categories: MenuCategory[];
  defaultCategoryId?: string;
  item?: MenuItem | null;
}

export function ItemFormDialog({
  open,
  onOpenChange,
  categories,
  defaultCategoryId,
  item,
}: Props) {
  const save = useSaveItem();
  const isEdit = !!item;

  const [name, setName] = useState("");
  const [description, setDescription] = useState("");
  const [price, setPrice] = useState("");
  const [compareAtPrice, setCompareAtPrice] = useState("");
  const [categoryId, setCategoryId] = useState("");
  const [imageUrl, setImageUrl] = useState<string | null>(null);
  const [isAvailable, setIsAvailable] = useState(true);
  const [isFeatured, setIsFeatured] = useState(false);

  useEffect(() => {
    if (!open) return;
    setName(item?.name ?? "");
    setDescription(item?.description ?? "");
    setPrice(item ? String(item.price) : "");
    setCompareAtPrice(item?.compareAtPrice ? String(item.compareAtPrice) : "");
    setCategoryId(item?.categoryId ?? defaultCategoryId ?? categories[0]?.id ?? "");
    setImageUrl(item?.imageUrl ?? null);
    setIsAvailable(item?.isAvailable ?? true);
    setIsFeatured(item?.isFeatured ?? false);
  }, [open, item, defaultCategoryId, categories]);

  const valid = name.trim() && price !== "" && categoryId;

  const submit = () => {
    save.mutate(
      {
        id: item?.id,
        categoryId,
        name: name.trim(),
        description: description.trim() || null,
        price: Number(price),
        compareAtPrice: compareAtPrice ? Number(compareAtPrice) : null,
        imageUrl,
        isAvailable,
        isFeatured,
      },
      { onSuccess: () => onOpenChange(false) }
    );
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-h-[90vh] overflow-y-auto sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>{isEdit ? "Edit item" : "New item"}</DialogTitle>
        </DialogHeader>

        <div className="space-y-4">
          <ImageUpload value={imageUrl} onChange={setImageUrl} />

          <div className="space-y-2">
            <Label htmlFor="name">Name</Label>
            <Input
              id="name"
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="e.g. Chicken Biryani"
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="desc">Description</Label>
            <Textarea
              id="desc"
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="Short description…"
            />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div className="space-y-2">
              <Label htmlFor="price">Price (৳)</Label>
              <Input
                id="price"
                type="number"
                min={0}
                value={price}
                onChange={(e) => setPrice(e.target.value)}
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="compare">Compare-at (৳)</Label>
              <Input
                id="compare"
                type="number"
                min={0}
                value={compareAtPrice}
                onChange={(e) => setCompareAtPrice(e.target.value)}
                placeholder="Optional"
              />
            </div>
          </div>

          <div className="space-y-2">
            <Label>Category</Label>
            <Select value={categoryId} onValueChange={setCategoryId}>
              <SelectTrigger className="w-full">
                <SelectValue placeholder="Select category" />
              </SelectTrigger>
              <SelectContent>
                {categories.map((c) => (
                  <SelectItem key={c.id} value={c.id}>
                    {c.name}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>

          <div className="flex items-center justify-between rounded-lg border p-3">
            <div>
              <p className="text-sm font-medium">Available</p>
              <p className="text-muted-foreground text-xs">
                Show this item to customers
              </p>
            </div>
            <Switch checked={isAvailable} onCheckedChange={setIsAvailable} />
          </div>
          <div className="flex items-center justify-between rounded-lg border p-3">
            <div>
              <p className="text-sm font-medium">Featured</p>
              <p className="text-muted-foreground text-xs">
                Highlight in featured sections
              </p>
            </div>
            <Switch checked={isFeatured} onCheckedChange={setIsFeatured} />
          </div>
        </div>

        <DialogFooter>
          <Button variant="outline" onClick={() => onOpenChange(false)}>
            Cancel
          </Button>
          <Button disabled={!valid || save.isPending} onClick={submit}>
            {save.isPending && <Spinner />}
            {isEdit ? "Save changes" : "Create item"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
