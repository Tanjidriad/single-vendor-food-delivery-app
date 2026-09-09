"use client";

import { useState } from "react";
import type { ColumnDef } from "@tanstack/react-table";
import { Ban, CheckCircle2, MoreVertical } from "lucide-react";

import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { ConfirmDialog } from "@/components/common/confirm-dialog";
import { ROLE_LABELS } from "@/lib/auth/roles";
import { useUpdateUserStatus } from "@/lib/api/queries/users";
import { formatDate, getInitials } from "@/lib/utils";
import type { UserListItem, UserStatus } from "@/types";

const statusVariant: Record<UserStatus, "success" | "destructive" | "muted"> = {
  ACTIVE: "success",
  SUSPENDED: "destructive",
  INACTIVE: "muted",
};

function UserActionsCell({ user }: { user: UserListItem }) {
  const update = useUpdateUserStatus();
  const [confirm, setConfirm] = useState(false);
  const suspending = user.status === "ACTIVE";
  const nextStatus: UserStatus = suspending ? "SUSPENDED" : "ACTIVE";

  return (
    <>
      <DropdownMenu>
        <DropdownMenuTrigger asChild>
          <Button variant="ghost" size="icon-sm" aria-label="User actions">
            <MoreVertical className="size-4" />
          </Button>
        </DropdownMenuTrigger>
        <DropdownMenuContent align="end">
          <DropdownMenuItem
            variant={suspending ? "destructive" : "default"}
            onClick={() => setConfirm(true)}
          >
            {suspending ? (
              <>
                <Ban className="size-4" /> Suspend
              </>
            ) : (
              <>
                <CheckCircle2 className="size-4" /> Activate
              </>
            )}
          </DropdownMenuItem>
        </DropdownMenuContent>
      </DropdownMenu>

      <ConfirmDialog
        open={confirm}
        onOpenChange={setConfirm}
        title={suspending ? "Suspend account?" : "Activate account?"}
        description={
          suspending
            ? `${user.name} won't be able to sign in until reactivated.`
            : `${user.name} will regain access to their account.`
        }
        confirmLabel={suspending ? "Suspend" : "Activate"}
        destructive={suspending}
        pending={update.isPending}
        onConfirm={() =>
          update.mutate(
            { id: user.id, status: nextStatus },
            { onSuccess: () => setConfirm(false) }
          )
        }
      />
    </>
  );
}

export const userColumns: ColumnDef<UserListItem>[] = [
  {
    accessorKey: "name",
    header: "Customer",
    cell: ({ row }) => {
      const u = row.original;
      return (
        <div className="flex items-center gap-3">
          <Avatar className="size-9">
            {u.avatarUrl && <AvatarImage src={u.avatarUrl} alt="" />}
            <AvatarFallback className="bg-primary/10 text-primary text-xs font-semibold">
              {getInitials(u.name)}
            </AvatarFallback>
          </Avatar>
          <div className="min-w-0">
            <p className="truncate font-medium">{u.name}</p>
            <p className="text-muted-foreground truncate text-xs">
              {u.email || u.phone || "—"}
            </p>
          </div>
        </div>
      );
    },
  },
  {
    accessorKey: "role",
    header: "Role",
    cell: ({ row }) => (
      <Badge variant="secondary">{ROLE_LABELS[row.original.role]}</Badge>
    ),
  },
  {
    accessorKey: "status",
    header: "Status",
    cell: ({ row }) => (
      <Badge variant={statusVariant[row.original.status]}>
        {row.original.status}
      </Badge>
    ),
  },
  {
    accessorKey: "totalOrders",
    header: "Orders",
    cell: ({ row }) => (
      <span className="tabular-nums">{row.original.totalOrders}</span>
    ),
  },
  {
    accessorKey: "createdAt",
    header: "Joined",
    cell: ({ row }) => (
      <span className="text-muted-foreground text-sm">
        {formatDate(row.original.createdAt)}
      </span>
    ),
  },
  {
    id: "actions",
    header: "",
    cell: ({ row }) => <UserActionsCell user={row.original} />,
  },
];
