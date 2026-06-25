"use client";

import { Bike, Check, FileText, Phone, X } from "lucide-react";

import { Card } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Spinner } from "@/components/common/spinner";
import { useApproveRider } from "@/lib/api/queries/riders";
import { formatDate } from "@/lib/utils";
import type { PendingRider } from "@/types";

export function PendingRiderCard({ rider }: { rider: PendingRider }) {
  const approve = useApproveRider();

  return (
    <Card className="gap-4 p-4">
      <div className="flex items-start gap-3">
        <div className="bg-primary/10 text-primary flex size-10 items-center justify-center rounded-full">
          <Bike className="size-5" />
        </div>
        <div className="min-w-0 flex-1">
          <p className="font-medium">{rider.fullName || "New rider"}</p>
          <p className="text-muted-foreground flex items-center gap-1.5 text-sm">
            <Phone className="size-3.5" /> {rider.phone || "—"}
          </p>
        </div>
        <Badge variant="warning">Pending</Badge>
      </div>

      <div className="text-muted-foreground flex flex-wrap items-center gap-x-4 gap-y-1 text-xs">
        <span>Vehicle: {rider.vehicleType || "—"}</span>
        <span>Applied {formatDate(rider.createdAt)}</span>
      </div>

      {rider.documents.length > 0 && (
        <div className="space-y-1.5">
          <p className="text-muted-foreground text-xs font-medium">Documents</p>
          <div className="flex flex-wrap gap-2">
            {rider.documents.map((doc) => (
              <a
                key={doc.id}
                href={doc.url}
                target="_blank"
                rel="noopener noreferrer"
                className="border-input hover:bg-accent inline-flex items-center gap-1.5 rounded-md border px-2 py-1 text-xs"
              >
                <FileText className="size-3.5" />
                {doc.type}
              </a>
            ))}
          </div>
        </div>
      )}

      <div className="flex gap-2">
        <Button
          className="flex-1"
          disabled={approve.isPending}
          onClick={() => approve.mutate({ id: rider.id, status: "APPROVED" })}
        >
          {approve.isPending && approve.variables?.status === "APPROVED" ? (
            <Spinner />
          ) : (
            <Check className="size-4" />
          )}
          Approve
        </Button>
        <Button
          variant="outline"
          className="text-destructive flex-1"
          disabled={approve.isPending}
          onClick={() => approve.mutate({ id: rider.id, status: "REJECTED" })}
        >
          {approve.isPending && approve.variables?.status === "REJECTED" ? (
            <Spinner />
          ) : (
            <X className="size-4" />
          )}
          Reject
        </Button>
      </div>
    </Card>
  );
}
