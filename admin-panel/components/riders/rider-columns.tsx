"use client";

import { useState } from "react";
import type { ColumnDef } from "@tanstack/react-table";
import { Ban, CheckCircle2, MoreVertical, Star } from "lucide-react";

import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { ConfirmDialog } from "@/components/common/confirm-dialog";
import { useApproveRider } from "@/lib/api/queries/riders";
import { getInitials } from "@/lib/utils";
import type { RiderApprovalStatus, RiderListItem } from "@/types";

const approvalVariant: Record<
  RiderApprovalStatus,
  "success" | "warning" | "destructive" | "muted"
> = {
  APPROVED: "success",
  PENDING: "warning",
  REJECTED: "destructive",
  SUSPENDED: "muted",
};

function RiderActionsCell({ rider }: { rider: RiderListItem }) {
  const approve = useApproveRider();
  const [action, setAction] = useState<"SUSPENDED" | "APPROVED" | null>(null);
  const isSuspended = rider.approvalStatus === "SUSPENDED";

  return (
    <>
      <DropdownMenu>
        <DropdownMenuTrigger asChild>
          <Button variant="ghost" size="icon-sm" aria-label="Rider actions">
            <MoreVertical className="size-4" />
          </Button>
        </DropdownMenuTrigger>
        <DropdownMenuContent align="end">
          {isSuspended ? (
            <DropdownMenuItem onClick={() => setAction("APPROVED")}>
              <CheckCircle2 className="size-4" /> Reinstate
            </DropdownMenuItem>
          ) : (
            <DropdownMenuItem
              variant="destructive"
              onClick={() => setAction("SUSPENDED")}
            >
              <Ban className="size-4" /> Suspend
            </DropdownMenuItem>
          )}
        </DropdownMenuContent>
      </DropdownMenu>

      <ConfirmDialog
        open={!!action}
        onOpenChange={(o) => !o && setAction(null)}
        title={action === "SUSPENDED" ? "Suspend rider?" : "Reinstate rider?"}
        description={
          action === "SUSPENDED"
            ? `${rider.fullName ?? "This rider"} will stop receiving delivery offers.`
            : `${rider.fullName ?? "This rider"} will be able to receive offers again.`
        }
        confirmLabel={action === "SUSPENDED" ? "Suspend" : "Reinstate"}
        destructive={action === "SUSPENDED"}
        pending={approve.isPending}
        onConfirm={() =>
          action &&
          approve.mutate(
            { id: rider.id, status: action },
            { onSuccess: () => setAction(null) }
          )
        }
      />
    </>
  );
}

export const riderColumns: ColumnDef<RiderListItem>[] = [
  {
    accessorKey: "fullName",
    header: "Rider",
    cell: ({ row }) => {
      const r = row.original;
      return (
        <div className="flex items-center gap-3">
          <Avatar className="size-9">
            <AvatarFallback className="bg-primary/10 text-primary text-xs font-semibold">
              {getInitials(r.fullName)}
            </AvatarFallback>
          </Avatar>
          <div className="min-w-0">
            <p className="truncate font-medium">{r.fullName || "Rider"}</p>
            <p className="text-muted-foreground truncate text-xs">
              {r.phone || r.email || "—"}
            </p>
          </div>
        </div>
      );
    },
  },
  {
    id: "online",
    header: "Availability",
    cell: ({ row }) => (
      <div className="flex items-center gap-2">
        <span
          className={`size-2 rounded-full ${row.original.isOnline ? "bg-success" : "bg-muted-foreground/40"}`}
        />
        <span className="text-sm">
          {row.original.isOnline ? "Online" : "Offline"}
        </span>
      </div>
    ),
  },
  {
    accessorKey: "approvalStatus",
    header: "Status",
    cell: ({ row }) => (
      <Badge variant={approvalVariant[row.original.approvalStatus]}>
        {row.original.approvalStatus}
      </Badge>
    ),
  },
  {
    accessorKey: "ratingAvg",
    header: "Rating",
    cell: ({ row }) =>
      row.original.ratingAvg != null ? (
        <span className="flex items-center gap-1 tabular-nums">
          <Star className="size-3.5 fill-amber-400 text-amber-400" />
          {row.original.ratingAvg.toFixed(1)}
        </span>
      ) : (
        <span className="text-muted-foreground">—</span>
      ),
  },
  {
    accessorKey: "totalDeliveries",
    header: "Deliveries",
    cell: ({ row }) => (
      <span className="tabular-nums">{row.original.totalDeliveries}</span>
    ),
  },
  {
    accessorKey: "exceptionCount30d",
    header: "Issues (30d)",
    cell: ({ row }) => {
      const n = row.original.exceptionCount30d;
      return (
        <span className={n > 0 ? "text-destructive font-medium tabular-nums" : "tabular-nums"}>
          {n}
        </span>
      );
    },
  },
  {
    id: "actions",
    header: "",
    cell: ({ row }) => (
      <div onClick={(e) => e.stopPropagation()}>
        <RiderActionsCell rider={row.original} />
      </div>
    ),
  },
];
