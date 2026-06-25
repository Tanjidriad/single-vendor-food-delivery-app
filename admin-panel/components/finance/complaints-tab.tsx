"use client";

import { useEffect, useState } from "react";
import { MessageSquareWarning } from "lucide-react";

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
import { Badge } from "@/components/ui/badge";
import { Card } from "@/components/ui/card";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Skeleton } from "@/components/ui/skeleton";
import { Spinner } from "@/components/common/spinner";
import { EmptyState } from "@/components/common/empty-state";
import { ErrorState } from "@/components/common/error-state";
import { useComplaints, useUpdateComplaint } from "@/lib/api/queries/finance";
import { formatDateTime } from "@/lib/utils";
import type { Complaint, ComplaintStatus } from "@/types";

const STATUS_META: Record<
  ComplaintStatus,
  { label: string; variant: "warning" | "info" | "success" | "destructive" }
> = {
  OPEN: { label: "Open", variant: "warning" },
  IN_REVIEW: { label: "In review", variant: "info" },
  RESOLVED: { label: "Resolved", variant: "success" },
  REJECTED: { label: "Rejected", variant: "destructive" },
};

const FILTERS: { value: ComplaintStatus | "ALL"; label: string }[] = [
  { value: "ALL", label: "All" },
  { value: "OPEN", label: "Open" },
  { value: "IN_REVIEW", label: "In review" },
  { value: "RESOLVED", label: "Resolved" },
  { value: "REJECTED", label: "Rejected" },
];

export function ComplaintsTab() {
  const [filter, setFilter] = useState<ComplaintStatus | "ALL">("ALL");
  const { data, isLoading, isError, refetch } = useComplaints(
    filter === "ALL" ? "" : filter
  );
  const [active, setActive] = useState<Complaint | null>(null);

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <p className="text-muted-foreground text-sm">
          Customer complaints and refund requests.
        </p>
        <Select
          value={filter}
          onValueChange={(v) => setFilter(v as ComplaintStatus | "ALL")}
        >
          <SelectTrigger className="w-40" size="sm">
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            {FILTERS.map((f) => (
              <SelectItem key={f.value} value={f.value}>
                {f.label}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      {isError ? (
        <ErrorState message="Couldn't load complaints." onRetry={() => refetch()} />
      ) : isLoading ? (
        <div className="space-y-3">
          {Array.from({ length: 3 }).map((_, i) => (
            <Skeleton key={i} className="h-28 w-full rounded-xl" />
          ))}
        </div>
      ) : !data?.length ? (
        <EmptyState
          icon={MessageSquareWarning}
          title="No complaints"
          description="Customer complaints and refund requests will appear here."
        />
      ) : (
        <div className="space-y-3">
          {data.map((c) => {
            const meta = STATUS_META[c.status];
            return (
              <Card key={c.id} className="gap-2 p-4">
                <div className="flex items-start justify-between gap-3">
                  <div className="min-w-0">
                    <div className="flex items-center gap-2">
                      <p className="truncate font-medium">{c.subject}</p>
                      <Badge variant={meta.variant}>{meta.label}</Badge>
                      {c.type === "REFUND_REQUEST" && (
                        <Badge variant="secondary">Refund</Badge>
                      )}
                    </div>
                    <p className="text-muted-foreground mt-0.5 line-clamp-2 text-sm">
                      {c.description}
                    </p>
                  </div>
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => setActive(c)}
                  >
                    Review
                  </Button>
                </div>
                <div className="text-muted-foreground flex flex-wrap gap-x-4 text-xs">
                  {c.order?.orderNumber && <span>Order #{c.order.orderNumber}</span>}
                  <span>{c.user?.email || c.user?.phone || "Customer"}</span>
                  <span>{formatDateTime(c.createdAt)}</span>
                </div>
              </Card>
            );
          })}
        </div>
      )}

      <ResolveDialog
        complaint={active}
        onClose={() => setActive(null)}
      />
    </div>
  );
}

function ResolveDialog({
  complaint,
  onClose,
}: {
  complaint: Complaint | null;
  onClose: () => void;
}) {
  const update = useUpdateComplaint();
  const [status, setStatus] = useState<ComplaintStatus>("IN_REVIEW");
  const [staffNote, setStaffNote] = useState("");
  const [refundAmount, setRefundAmount] = useState("");

  useEffect(() => {
    if (!complaint) return;
    setStatus(complaint.status);
    setStaffNote(complaint.staffNote ?? "");
    setRefundAmount(
      complaint.refundAmount != null ? String(complaint.refundAmount) : ""
    );
  }, [complaint]);

  return (
    <Dialog open={!!complaint} onOpenChange={(o) => !o && onClose()}>
      <DialogContent className="max-w-md">
        <DialogHeader>
          <DialogTitle>{complaint?.subject}</DialogTitle>
        </DialogHeader>
        <div className="space-y-4">
          <p className="text-muted-foreground text-sm">{complaint?.description}</p>
          <div className="space-y-2">
            <Label>Status</Label>
            <Select
              value={status}
              onValueChange={(v) => setStatus(v as ComplaintStatus)}
            >
              <SelectTrigger className="w-full">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                {(["OPEN", "IN_REVIEW", "RESOLVED", "REJECTED"] as ComplaintStatus[]).map(
                  (s) => (
                    <SelectItem key={s} value={s}>
                      {STATUS_META[s].label}
                    </SelectItem>
                  )
                )}
              </SelectContent>
            </Select>
          </div>
          <div className="space-y-2">
            <Label htmlFor="staff-note">Internal note</Label>
            <Textarea
              id="staff-note"
              value={staffNote}
              onChange={(e) => setStaffNote(e.target.value)}
              placeholder="Resolution details…"
            />
          </div>
          {complaint?.type === "REFUND_REQUEST" && (
            <div className="space-y-2">
              <Label htmlFor="refund">Refund amount (৳)</Label>
              <input
                id="refund"
                type="number"
                min={0}
                value={refundAmount}
                onChange={(e) => setRefundAmount(e.target.value)}
                className="border-input flex h-9 w-full rounded-md border bg-transparent px-3 py-1 text-sm shadow-sm outline-none focus-visible:ring-[3px] focus-visible:ring-ring/50"
              />
            </div>
          )}
        </div>
        <DialogFooter>
          <Button variant="outline" onClick={onClose}>
            Cancel
          </Button>
          <Button
            disabled={!complaint || update.isPending}
            onClick={() =>
              complaint &&
              update.mutate(
                {
                  id: complaint.id,
                  status,
                  staffNote: staffNote || undefined,
                  refundAmount: refundAmount ? Number(refundAmount) : undefined,
                },
                { onSuccess: onClose }
              )
            }
          >
            {update.isPending && <Spinner />}
            Save
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
