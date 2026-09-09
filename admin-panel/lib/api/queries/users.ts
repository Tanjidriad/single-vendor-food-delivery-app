"use client";

import {
  useMutation,
  useQuery,
  useQueryClient,
} from "@tanstack/react-query";
import { toast } from "sonner";

import { api, ApiError, qs } from "@/lib/api/client";
import { endpoints } from "@/lib/api/endpoints";
import type { ListResponse, UserListItem, UserRole, UserStatus } from "@/types";

export interface UserFilters {
  role?: UserRole | "";
  search?: string;
  page?: number;
  limit?: number;
}

export function useUsers(filters: UserFilters) {
  return useQuery({
    queryKey: ["users", "list", filters],
    queryFn: () =>
      api.get<ListResponse<UserListItem>>(
        `${endpoints.users.list}${qs({
          role: filters.role,
          search: filters.search,
          page: filters.page ?? 1,
          limit: filters.limit ?? 25,
        })}`
      ),
    placeholderData: (prev) => prev,
  });
}

export function useUpdateUserStatus() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, status }: { id: string; status: UserStatus }) =>
      api.patch(endpoints.users.status(id), { status }),
    onSuccess: (_d, { status }) => {
      toast.success(
        status === "ACTIVE" ? "Account activated" : "Account suspended"
      );
      qc.invalidateQueries({ queryKey: ["users"] });
    },
    onError: (e) =>
      toast.error(e instanceof ApiError ? e.message : "Couldn't update account"),
  });
}
