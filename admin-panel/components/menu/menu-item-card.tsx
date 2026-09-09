"use client";

import { useState } from "react";
import { MoreVertical, Pencil, Star, Trash2, UtensilsCrossed } from "lucide-react";

import { Badge } from "@/components/ui/badge";
import { Switch } from "@/components/ui/switch";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { Button } from "@/components/ui/button";
import { ConfirmDialog } from "@/components/common/confirm-dialog";
import {
  useDeleteItem,
  useToggleItemFlag,
} from "@/lib/api/queries/menu";
import { formatCurrency, cn } from "@/lib/utils";
import type { MenuItem } from "@/types";

export function MenuItemCard({
  item,
  onEdit,
}: {
  item: MenuItem;
  onEdit: (item: MenuItem) => void;
}) {
  const toggle = useToggleItemFlag();
  const del = useDeleteItem();
  const [confirmOpen, setConfirmOpen] = useState(false);

  return (
    <div
      className={cn(
        "bg-card flex items-center gap-3 rounded-xl border p-3 transition-shadow hover:shadow-sm",
        !item.isAvailable && "opacity-70"
      )}
    >
      <div className="bg-muted size-14 shrink-0 overflow-hidden rounded-lg">
        {item.imageUrl ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img src={item.imageUrl} alt="" className="size-full object-cover" />
        ) : (
          <div className="text-muted-foreground flex size-full items-center justify-center">
            <UtensilsCrossed className="size-5" />
          </div>
        )}
      </div>

      <div className="min-w-0 flex-1">
        <div className="flex items-center gap-1.5">
          <p className="truncate font-medium">{item.name}</p>
          {item.isFeatured && (
            <Star className="size-3.5 shrink-0 fill-amber-400 text-amber-400" />
          )}
        </div>
        <p className="text-muted-foreground truncate text-xs">
          {item.description || "No description"}
        </p>
        <div className="mt-1 flex items-center gap-2">
          <span className="font-semibold tabular-nums">
            {formatCurrency(item.price)}
          </span>
          {item.compareAtPrice ? (
            <span className="text-muted-foreground text-xs line-through tabular-nums">
              {formatCurrency(item.compareAtPrice)}
            </span>
          ) : null}
        </div>
      </div>

      <div className="flex flex-col items-end gap-2">
        <DropdownMenu>
          <DropdownMenuTrigger asChild>
            <Button variant="ghost" size="icon-sm" aria-label="Item actions">
              <MoreVertical className="size-4" />
            </Button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end">
            <DropdownMenuItem onClick={() => onEdit(item)}>
              <Pencil className="size-4" /> Edit
            </DropdownMenuItem>
            <DropdownMenuItem
              variant="destructive"
              onClick={() => setConfirmOpen(true)}
            >
              <Trash2 className="size-4" /> Delete
            </DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>

        <div className="flex items-center gap-1.5">
          <Badge variant={item.isAvailable ? "success" : "muted"}>
            {item.isAvailable ? "Live" : "Hidden"}
          </Badge>
          <Switch
            checked={item.isAvailable}
            disabled={toggle.isPending}
            onCheckedChange={(v) =>
              toggle.mutate({ id: item.id, field: "isAvailable", value: v })
            }
            aria-label="Toggle availability"
          />
        </div>
      </div>

      <ConfirmDialog
        open={confirmOpen}
        onOpenChange={setConfirmOpen}
        title="Delete item?"
        description={`"${item.name}" will be permanently removed from your menu.`}
        confirmLabel="Delete"
        destructive
        pending={del.isPending}
        onConfirm={() =>
          del.mutate(item.id, { onSuccess: () => setConfirmOpen(false) })
        }
      />
    </div>
  );
}
