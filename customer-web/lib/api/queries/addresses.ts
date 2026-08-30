"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import { api } from "@/lib/api/client";
import { endpoints } from "@/lib/api/endpoints";
import { useAuth } from "@/lib/auth/use-auth";
import type { Address, AddressLabel } from "@/types";

export interface AddressInput {
  label: AddressLabel;
  line1: string;
  line2?: string;
  city?: string;
  postalCode?: string;
  latitude: number;
  longitude: number;
  instructions?: string;
  isDefault?: boolean;
}

export function useAddresses() {
  const { isAuthenticated } = useAuth();
  return useQuery({
    queryKey: ["addresses"],
    enabled: isAuthenticated,
    queryFn: () => api.get<Address[]>(endpoints.addresses.list),
  });
}

export function useCreateAddress() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (input: AddressInput) =>
      api.post<Address>(endpoints.addresses.create, input),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["addresses"] }),
  });
}

export function useUpdateAddress() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, ...input }: AddressInput & { id: string }) =>
      api.patch<Address>(endpoints.addresses.update(id), input),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["addresses"] }),
  });
}

export function useDeleteAddress() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => api.delete(endpoints.addresses.remove(id)),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["addresses"] }),
  });
}
