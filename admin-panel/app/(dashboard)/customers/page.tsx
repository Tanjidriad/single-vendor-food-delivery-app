"use client";

import { useState } from "react";
import { Search, X } from "lucide-react";

import { PageHeader } from "@/components/common/page-header";
import { ErrorState } from "@/components/common/error-state";
import { DataTable } from "@/components/data-table/data-table";
import { userColumns } from "@/components/customers/user-columns";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { useUsers } from "@/lib/api/queries/users";
import { useDebounce } from "@/lib/hooks/use-debounce";
import type { UserRole } from "@/types";

const ALL = "ALL";
const ROLE_OPTIONS: { value: UserRole; label: string }[] = [
  { value: "CUSTOMER", label: "Customers" },
  { value: "RIDER", label: "Riders" },
  { value: "OWNER", label: "Owners" },
  { value: "MANAGER", label: "Managers" },
  { value: "CASHIER", label: "Cashiers" },
  { value: "KITCHEN", label: "Kitchen" },
];

export default function CustomersPage() {
  const [search, setSearch] = useState("");
  const [role, setRole] = useState<UserRole | typeof ALL>("CUSTOMER");
  const [page, setPage] = useState(1);
  const debouncedSearch = useDebounce(search);

  const { data, isLoading, isError, refetch, isFetching } = useUsers({
    search: debouncedSearch,
    role: role === ALL ? "" : role,
    page,
    limit: 25,
  });

  const hasFilters = search !== "" || role !== "CUSTOMER";

  return (
    <div className="space-y-6">
      <PageHeader
        title="Customers"
        description="Browse customers and staff, and manage account access."
      />

      <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
        <div className="relative flex-1 sm:max-w-xs">
          <Search className="text-muted-foreground absolute top-1/2 left-3 size-4 -translate-y-1/2" />
          <Input
            placeholder="Search name, email, or phone…"
            value={search}
            onChange={(e) => {
              setSearch(e.target.value);
              setPage(1);
            }}
            className="pl-9"
          />
        </div>
        <Select
          value={role}
          onValueChange={(v) => {
            setRole(v as UserRole | typeof ALL);
            setPage(1);
          }}
        >
          <SelectTrigger className="w-full sm:w-44">
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value={ALL}>All roles</SelectItem>
            {ROLE_OPTIONS.map((opt) => (
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
              setRole("CUSTOMER");
              setPage(1);
            }}
          >
            <X className="size-4" /> Reset
          </Button>
        )}
      </div>

      {isError ? (
        <ErrorState message="Couldn't load users." onRetry={() => refetch()} />
      ) : (
        <DataTable
          columns={userColumns}
          data={data?.data ?? []}
          loading={isLoading || (isFetching && !data)}
          emptyTitle="No users found"
          emptyDescription="Try a different search or role filter."
          page={page}
          totalPages={data?.meta.totalPages ?? 1}
          total={data?.meta.total}
          onPageChange={setPage}
        />
      )}
    </div>
  );
}
