"use client";

import { Suspense, useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { Search, X } from "lucide-react";

import { PageHeader } from "@/components/common/page-header";
import { ErrorState } from "@/components/common/error-state";
import { DataTable } from "@/components/data-table/data-table";
import { orderColumns } from "@/components/orders/order-columns";
import { OrderDetailSheet } from "@/components/orders/order-detail-sheet";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { useOrders } from "@/lib/api/queries/orders";
import { ORDER_STATUS_OPTIONS } from "@/lib/order-status";
import { useDebounce } from "@/lib/hooks/use-debounce";
import type { OrderListItem, OrderStatus } from "@/types";

const ALL = "ALL";

function OrdersView() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const selectedId = searchParams.get("id");

  const [search, setSearch] = useState("");
  const [status, setStatus] = useState<OrderStatus | typeof ALL>(ALL);
  const [page, setPage] = useState(1);
  const debouncedSearch = useDebounce(search);

  const { data, isLoading, isError, refetch, isFetching } = useOrders({
    search: debouncedSearch,
    status: status === ALL ? "" : status,
    page,
    limit: 25,
  });

  const openOrder = (order: OrderListItem) => {
    const params = new URLSearchParams(searchParams.toString());
    params.set("id", order.id);
    router.replace(`/orders?${params.toString()}`, { scroll: false });
  };

  const closeOrder = () => {
    const params = new URLSearchParams(searchParams.toString());
    params.delete("id");
    const q = params.toString();
    router.replace(q ? `/orders?${q}` : "/orders", { scroll: false });
  };

  const hasFilters = search !== "" || status !== ALL;

  return (
    <div className="space-y-6">
      <PageHeader
        title="Orders"
        description="Search, filter, and manage every order."
      />

      <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
        <div className="relative flex-1 sm:max-w-xs">
          <Search className="text-muted-foreground absolute top-1/2 left-3 size-4 -translate-y-1/2" />
          <Input
            placeholder="Search order # or customer…"
            value={search}
            onChange={(e) => {
              setSearch(e.target.value);
              setPage(1);
            }}
            className="pl-9"
          />
        </div>
        <Select
          value={status}
          onValueChange={(v) => {
            setStatus(v as OrderStatus | typeof ALL);
            setPage(1);
          }}
        >
          <SelectTrigger className="w-full sm:w-48">
            <SelectValue placeholder="All statuses" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value={ALL}>All statuses</SelectItem>
            {ORDER_STATUS_OPTIONS.map((opt) => (
              <SelectItem key={opt.value} value={opt.value}>
                {opt.label}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
        {hasFilters && (
          <Button
            variant="ghost"
            size="sm"
            onClick={() => {
              setSearch("");
              setStatus(ALL);
              setPage(1);
            }}
          >
            <X className="size-4" /> Clear
          </Button>
        )}
      </div>

      {isError ? (
        <ErrorState
          message="Couldn't load orders."
          onRetry={() => refetch()}
        />
      ) : (
        <DataTable
          columns={orderColumns}
          data={data?.data ?? []}
          loading={isLoading || (isFetching && !data)}
          onRowClick={openOrder}
          emptyTitle="No orders found"
          emptyDescription={
            hasFilters
              ? "Try adjusting your search or filters."
              : "Orders will appear here as customers place them."
          }
          page={page}
          totalPages={data?.meta.totalPages ?? 1}
          total={data?.meta.total}
          onPageChange={setPage}
        />
      )}

      <OrderDetailSheet
        orderId={selectedId}
        open={!!selectedId}
        onOpenChange={(o) => !o && closeOrder()}
      />
    </div>
  );
}

export default function OrdersPage() {
  return (
    <Suspense fallback={null}>
      <OrdersView />
    </Suspense>
  );
}
