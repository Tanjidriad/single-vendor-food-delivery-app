"use client";

import { useState } from "react";
import { BadgeCheck, Bike } from "lucide-react";

import { PageHeader } from "@/components/common/page-header";
import { ErrorState } from "@/components/common/error-state";
import { EmptyState } from "@/components/common/empty-state";
import { DataTable } from "@/components/data-table/data-table";
import { riderColumns } from "@/components/riders/rider-columns";
import { PendingRiderCard } from "@/components/riders/pending-rider-card";
import { RiderDetailSheet } from "@/components/riders/rider-detail-sheet";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { usePendingRiders, useRiders } from "@/lib/api/queries/riders";
import type { RiderListItem } from "@/types";

export default function RidersPage() {
  const riders = useRiders();
  const pending = usePendingRiders();
  const pendingCount = pending.data?.length ?? 0;
  const [selected, setSelected] = useState<RiderListItem | null>(null);

  return (
    <div className="space-y-6">
      <PageHeader
        title="Riders"
        description="Manage your delivery fleet and approve new applicants."
      />

      <Tabs defaultValue="all">
        <TabsList>
          <TabsTrigger value="all">All riders</TabsTrigger>
          <TabsTrigger value="pending" className="gap-1.5">
            Pending
            {pendingCount > 0 && (
              <Badge variant="warning" className="px-1.5">
                {pendingCount}
              </Badge>
            )}
          </TabsTrigger>
        </TabsList>

        <TabsContent value="all" className="pt-4">
          {riders.isError ? (
            <ErrorState
              message="Couldn't load riders."
              onRetry={() => riders.refetch()}
            />
          ) : (
            <DataTable
              columns={riderColumns}
              data={riders.data ?? []}
              loading={riders.isLoading}
              onRowClick={setSelected}
              emptyTitle="No riders yet"
              emptyDescription="Approved riders will appear here."
            />
          )}
        </TabsContent>

        <TabsContent value="pending" className="pt-4">
          {pending.isError ? (
            <ErrorState
              message="Couldn't load pending riders."
              onRetry={() => pending.refetch()}
            />
          ) : pending.isLoading ? (
            <div className="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-3">
              {Array.from({ length: 3 }).map((_, i) => (
                <Skeleton key={i} className="h-52 w-full rounded-xl" />
              ))}
            </div>
          ) : pendingCount === 0 ? (
            <EmptyState
              icon={BadgeCheck}
              title="No pending applications"
              description="New rider applications will appear here for review."
            />
          ) : (
            <div className="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-3">
              {pending.data?.map((rider) => (
                <PendingRiderCard key={rider.id} rider={rider} />
              ))}
            </div>
          )}
        </TabsContent>
      </Tabs>

      <RiderDetailSheet
        rider={selected}
        open={!!selected}
        onOpenChange={(o) => !o && setSelected(null)}
      />
    </div>
  );
}
