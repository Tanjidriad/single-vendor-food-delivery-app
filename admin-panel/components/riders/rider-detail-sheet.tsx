"use client";

import { useEffect, useState } from "react";
import {
  AlertTriangle,
  Bike,
  Check,
  FileText,
  Mail,
  Package,
  Phone,
  Star,
  X,
} from "lucide-react";

import {
  Sheet,
  SheetContent,
  SheetHeader,
  SheetTitle,
} from "@/components/ui/sheet";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Spinner } from "@/components/common/spinner";
import { EmptyState } from "@/components/common/empty-state";
import { ConfirmDialog } from "@/components/common/confirm-dialog";
import {
  useApproveRider,
  useUpdateRiderDocument,
} from "@/lib/api/queries/riders";
import { formatDate, getInitials } from "@/lib/utils";
import type {
  RiderApprovalStatus,
  RiderDocument,
  RiderListItem,
} from "@/types";

const approvalVariant: Record<
  RiderApprovalStatus,
  "success" | "warning" | "destructive" | "muted"
> = {
  APPROVED: "success",
  PENDING: "warning",
  REJECTED: "destructive",
  SUSPENDED: "muted",
};

const docStatusVariant: Record<
  RiderDocument["status"],
  "success" | "warning" | "destructive"
> = {
  APPROVED: "success",
  PENDING: "warning",
  REJECTED: "destructive",
};

const isImage = (url: string) => /\.(png|jpe?g|webp|gif|avif)(\?|$)/i.test(url);

interface Props {
  rider: RiderListItem | null;
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

export function RiderDetailSheet({ rider, open, onOpenChange }: Props) {
  return (
    <Sheet open={open} onOpenChange={onOpenChange}>
      <SheetContent side="right" className="w-full sm:max-w-lg">
        {rider && (
          <RiderDetailBody rider={rider} onClose={() => onOpenChange(false)} />
        )}
      </SheetContent>
    </Sheet>
  );
}

function RiderDetailBody({
  rider,
  onClose,
}: {
  rider: RiderListItem;
  onClose: () => void;
}) {
  const approve = useApproveRider();
  const [action, setAction] = useState<
    "APPROVED" | "REJECTED" | "SUSPENDED" | null
  >(null);

  // Local doc state so per-document status changes reflect immediately,
  // independent of the (snapshot) rider prop passed from the table.
  const [docs, setDocs] = useState(rider.documents);
  useEffect(() => setDocs(rider.documents), [rider.id, rider.documents]);

  const stats = [
    {
      icon: Star,
      label: "Rating",
      value:
        rider.ratingAvg != null
          ? `${rider.ratingAvg.toFixed(1)} (${rider.ratingCount ?? 0})`
          : "—",
    },
    { icon: Package, label: "Deliveries", value: String(rider.totalDeliveries) },
    {
      icon: AlertTriangle,
      label: "Issues (30d)",
      value: String(rider.exceptionCount30d),
    },
    { icon: Bike, label: "Vehicle", value: rider.vehicleType || "—" },
  ];

  return (
    <>
      <SheetHeader>
        <div className="flex items-center gap-3">
          <div className="bg-primary/10 text-primary flex size-11 items-center justify-center rounded-full font-semibold">
            {getInitials(rider.fullName)}
          </div>
          <div className="min-w-0 flex-1">
            <SheetTitle className="truncate">
              {rider.fullName || "Rider"}
            </SheetTitle>
            <div className="mt-0.5 flex items-center gap-2">
              <Badge variant={approvalVariant[rider.approvalStatus]}>
                {rider.approvalStatus}
              </Badge>
              <span className="text-muted-foreground flex items-center gap-1 text-xs">
                <span
                  className={`size-1.5 rounded-full ${rider.isOnline ? "bg-success" : "bg-muted-foreground/40"}`}
                />
                {rider.isOnline ? "Online" : "Offline"}
              </span>
            </div>
          </div>
        </div>
      </SheetHeader>

      <div className="scrollbar-thin flex-1 space-y-5 overflow-y-auto p-5">
        {/* Contact */}
        <div className="text-muted-foreground flex flex-wrap gap-x-5 gap-y-1 text-sm">
          {rider.phone && (
            <span className="flex items-center gap-1.5">
              <Phone className="size-3.5" /> {rider.phone}
            </span>
          )}
          {rider.email && (
            <span className="flex items-center gap-1.5">
              <Mail className="size-3.5" /> {rider.email}
            </span>
          )}
        </div>

        {/* Stats */}
        <div className="grid grid-cols-2 gap-3">
          {stats.map((s) => (
            <div key={s.label} className="rounded-lg border p-3">
              <div className="text-muted-foreground flex items-center gap-1.5 text-xs">
                <s.icon className="size-3.5" />
                {s.label}
              </div>
              <p className="mt-1 font-semibold tabular-nums">{s.value}</p>
            </div>
          ))}
        </div>

        {/* Documents */}
        <section className="space-y-2">
          <p className="text-muted-foreground text-xs font-semibold uppercase tracking-wide">
            Documents ({docs.length})
          </p>
          {docs.length === 0 ? (
            <EmptyState
              icon={FileText}
              title="No documents uploaded"
              description="This rider hasn't submitted any verification documents yet."
              className="py-8"
            />
          ) : (
            <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
              {docs.map((doc) => (
                <DocumentCard
                  key={doc.id}
                  doc={doc}
                  onStatusChange={(status) =>
                    setDocs((prev) =>
                      prev.map((d) => (d.id === doc.id ? { ...d, status } : d))
                    )
                  }
                />
              ))}
            </div>
          )}
        </section>
      </div>

      {/* Actions */}
      <div className="flex gap-2 border-t p-5">
        {rider.approvalStatus === "PENDING" && (
          <>
            <Button
              className="flex-1"
              disabled={approve.isPending}
              onClick={() => setAction("APPROVED")}
            >
              Approve
            </Button>
            <Button
              variant="outline"
              className="text-destructive flex-1"
              disabled={approve.isPending}
              onClick={() => setAction("REJECTED")}
            >
              Reject
            </Button>
          </>
        )}
        {rider.approvalStatus === "APPROVED" && (
          <Button
            variant="outline"
            className="text-destructive ml-auto"
            disabled={approve.isPending}
            onClick={() => setAction("SUSPENDED")}
          >
            Suspend rider
          </Button>
        )}
        {(rider.approvalStatus === "SUSPENDED" ||
          rider.approvalStatus === "REJECTED") && (
          <Button
            className="ml-auto"
            disabled={approve.isPending}
            onClick={() => setAction("APPROVED")}
          >
            Reinstate rider
          </Button>
        )}
      </div>

      <ConfirmDialog
        open={!!action}
        onOpenChange={(o) => !o && setAction(null)}
        title={
          action === "APPROVED"
            ? "Approve rider?"
            : action === "REJECTED"
              ? "Reject rider?"
              : "Suspend rider?"
        }
        description={
          action === "SUSPENDED"
            ? `${rider.fullName ?? "This rider"} will stop receiving delivery offers.`
            : action === "REJECTED"
              ? `${rider.fullName ?? "This rider"}'s application will be rejected.`
              : `${rider.fullName ?? "This rider"} will be able to receive offers.`
        }
        confirmLabel={
          action === "APPROVED"
            ? "Approve"
            : action === "REJECTED"
              ? "Reject"
              : "Suspend"
        }
        destructive={action === "REJECTED" || action === "SUSPENDED"}
        pending={approve.isPending}
        onConfirm={() =>
          action &&
          approve.mutate(
            { id: rider.id, status: action },
            {
              onSuccess: () => {
                setAction(null);
                onClose();
              },
            }
          )
        }
      />
    </>
  );
}

function DocumentCard({
  doc,
  onStatusChange,
}: {
  doc: RiderDocument;
  onStatusChange: (status: RiderDocument["status"]) => void;
}) {
  const update = useUpdateRiderDocument();
  const set = (status: "APPROVED" | "REJECTED") =>
    update.mutate(
      { docId: doc.id, status },
      { onSuccess: () => onStatusChange(status) }
    );

  return (
    <div className="overflow-hidden rounded-lg border">
      <a
        href={doc.url}
        target="_blank"
        rel="noopener noreferrer"
        className="bg-muted hover:opacity-90 flex aspect-[4/3] items-center justify-center transition-opacity"
      >
        {isImage(doc.url) ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img src={doc.url} alt={doc.type} className="size-full object-cover" />
        ) : (
          <FileText className="text-muted-foreground size-8" />
        )}
      </a>
      <div className="space-y-2 p-2.5">
        <div className="flex items-center justify-between gap-2">
          <div className="min-w-0">
            <p className="truncate text-sm font-medium">{doc.type}</p>
            <p className="text-muted-foreground text-xs">
              {formatDate(doc.uploadedAt)}
            </p>
          </div>
          <Badge variant={docStatusVariant[doc.status]}>{doc.status}</Badge>
        </div>
        <div className="flex gap-1.5">
          <Button
            size="sm"
            variant={doc.status === "APPROVED" ? "default" : "outline"}
            className="h-7 flex-1"
            disabled={update.isPending}
            onClick={() => set("APPROVED")}
          >
            {update.isPending && update.variables?.status === "APPROVED" ? (
              <Spinner />
            ) : (
              <Check className="size-3.5" />
            )}
            Approve
          </Button>
          <Button
            size="sm"
            variant={doc.status === "REJECTED" ? "destructive" : "outline"}
            className="h-7 flex-1"
            disabled={update.isPending}
            onClick={() => set("REJECTED")}
          >
            {update.isPending && update.variables?.status === "REJECTED" ? (
              <Spinner />
            ) : (
              <X className="size-3.5" />
            )}
            Reject
          </Button>
        </div>
      </div>
    </div>
  );
}
