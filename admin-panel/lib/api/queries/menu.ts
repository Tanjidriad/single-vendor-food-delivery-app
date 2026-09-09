"use client";

import {
  useMutation,
  useQuery,
  useQueryClient,
} from "@tanstack/react-query";
import { toast } from "sonner";

import { api, ApiError } from "@/lib/api/client";
import { endpoints } from "@/lib/api/endpoints";
import type { Addon, MenuCategory } from "@/types";

const MENU_KEY = ["menu", "full"];
const ADDONS_KEY = ["menu", "addons"];

export function useMenu() {
  return useQuery({
    queryKey: MENU_KEY,
    queryFn: () => api.get<MenuCategory[]>(endpoints.menu.all),
  });
}

export function useAddons() {
  return useQuery({
    queryKey: ADDONS_KEY,
    queryFn: () => api.get<Addon[]>(endpoints.menu.addons),
  });
}

function errMsg(e: unknown, fallback: string) {
  return e instanceof ApiError ? e.message : fallback;
}

function useMenuInvalidate() {
  const qc = useQueryClient();
  return () => qc.invalidateQueries({ queryKey: ["menu"] });
}

/* ── Categories ─────────────────────────────────────────────── */

export function useSaveCategory() {
  const invalidate = useMenuInvalidate();
  return useMutation({
    mutationFn: ({ id, ...data }: { id?: string } & Record<string, unknown>) =>
      id
        ? api.patch(endpoints.menu.category(id), data)
        : api.post(endpoints.menu.categories, data),
    onSuccess: (_d, vars) => {
      toast.success(vars.id ? "Category updated" : "Category created");
      invalidate();
    },
    onError: (e) => toast.error(errMsg(e, "Couldn't save category")),
  });
}

export function useDeleteCategory() {
  const invalidate = useMenuInvalidate();
  return useMutation({
    mutationFn: (id: string) => api.delete(endpoints.menu.category(id)),
    onSuccess: () => {
      toast.success("Category deleted");
      invalidate();
    },
    onError: (e) => toast.error(errMsg(e, "Couldn't delete category")),
  });
}

/* ── Items ──────────────────────────────────────────────────── */

export function useSaveItem() {
  const invalidate = useMenuInvalidate();
  return useMutation({
    mutationFn: ({ id, ...data }: { id?: string } & Record<string, unknown>) =>
      id
        ? api.patch(endpoints.menu.item(id), data)
        : api.post(endpoints.menu.items, data),
    onSuccess: (_d, vars) => {
      toast.success(vars.id ? "Item updated" : "Item created");
      invalidate();
    },
    onError: (e) => toast.error(errMsg(e, "Couldn't save item")),
  });
}

export function useDeleteItem() {
  const invalidate = useMenuInvalidate();
  return useMutation({
    mutationFn: (id: string) => api.delete(endpoints.menu.item(id)),
    onSuccess: () => {
      toast.success("Item deleted");
      invalidate();
    },
    onError: (e) => toast.error(errMsg(e, "Couldn't delete item")),
  });
}

/** Optimistic availability/featured toggle with rollback. */
export function useToggleItemFlag() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({
      id,
      field,
      value,
    }: {
      id: string;
      field: "isAvailable" | "isFeatured";
      value: boolean;
    }) => api.patch(endpoints.menu.item(id), { [field]: value }),
    onMutate: async ({ id, field, value }) => {
      await qc.cancelQueries({ queryKey: MENU_KEY });
      const prev = qc.getQueryData<MenuCategory[]>(MENU_KEY);
      qc.setQueryData<MenuCategory[]>(MENU_KEY, (old) =>
        old?.map((cat) => ({
          ...cat,
          menuItems: cat.menuItems?.map((it) =>
            it.id === id ? { ...it, [field]: value } : it
          ),
        }))
      );
      return { prev };
    },
    onError: (e, _vars, ctx) => {
      if (ctx?.prev) qc.setQueryData(MENU_KEY, ctx.prev);
      toast.error(errMsg(e, "Couldn't update item"));
    },
    onSettled: () => qc.invalidateQueries({ queryKey: MENU_KEY }),
  });
}

/* ── Add-ons ────────────────────────────────────────────────── */

export function useSaveAddon() {
  const invalidate = useMenuInvalidate();
  return useMutation({
    mutationFn: ({ id, ...data }: { id?: string } & Record<string, unknown>) =>
      id
        ? api.patch(endpoints.menu.addon(id), data)
        : api.post(endpoints.menu.addons, data),
    onSuccess: (_d, vars) => {
      toast.success(vars.id ? "Add-on updated" : "Add-on created");
      invalidate();
    },
    onError: (e) => toast.error(errMsg(e, "Couldn't save add-on")),
  });
}

export function useDeleteAddon() {
  const invalidate = useMenuInvalidate();
  return useMutation({
    mutationFn: (id: string) => api.delete(endpoints.menu.addon(id)),
    onSuccess: () => {
      toast.success("Add-on deleted");
      invalidate();
    },
    onError: (e) => toast.error(errMsg(e, "Couldn't delete add-on")),
  });
}
