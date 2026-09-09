"use client";

import { useState } from "react";
import {
  FolderPlus,
  MoreVertical,
  Pencil,
  Plus,
  Trash2,
  UtensilsCrossed,
} from "lucide-react";

import { PageHeader } from "@/components/common/page-header";
import { ErrorState } from "@/components/common/error-state";
import { EmptyState } from "@/components/common/empty-state";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { MenuItemCard } from "@/components/menu/menu-item-card";
import { ItemFormDialog } from "@/components/menu/item-form-dialog";
import { CategoryFormDialog } from "@/components/menu/category-form-dialog";
import { AddonsManager } from "@/components/menu/addons-manager";
import { ConfirmDialog } from "@/components/common/confirm-dialog";
import { useDeleteCategory, useMenu } from "@/lib/api/queries/menu";
import type { MenuCategory, MenuItem } from "@/types";

export default function MenuPage() {
  const { data: categories, isLoading, isError, refetch } = useMenu();
  const delCategory = useDeleteCategory();

  const [itemDialog, setItemDialog] = useState<{
    open: boolean;
    item?: MenuItem | null;
    categoryId?: string;
  }>({ open: false });
  const [categoryDialog, setCategoryDialog] = useState<{
    open: boolean;
    category?: MenuCategory | null;
  }>({ open: false });
  const [deletingCat, setDeletingCat] = useState<MenuCategory | null>(null);

  const cats = categories ?? [];

  return (
    <div className="space-y-6">
      <PageHeader
        title="Menu"
        description="Manage categories, items, and add-ons."
        actions={
          <>
            <Button
              variant="outline"
              onClick={() => setCategoryDialog({ open: true, category: null })}
            >
              <FolderPlus className="size-4" /> Category
            </Button>
            <Button
              disabled={cats.length === 0}
              onClick={() => setItemDialog({ open: true, item: null })}
            >
              <Plus className="size-4" /> Item
            </Button>
          </>
        }
      />

      <Tabs defaultValue="menu">
        <TabsList>
          <TabsTrigger value="menu">Menu</TabsTrigger>
          <TabsTrigger value="addons">Add-ons</TabsTrigger>
        </TabsList>

        <TabsContent value="menu" className="pt-4">
          {isError ? (
            <ErrorState message="Couldn't load the menu." onRetry={() => refetch()} />
          ) : isLoading ? (
            <div className="space-y-6">
              {Array.from({ length: 2 }).map((_, i) => (
                <div key={i} className="space-y-3">
                  <Skeleton className="h-6 w-40" />
                  <div className="grid gap-3 md:grid-cols-2">
                    {Array.from({ length: 4 }).map((_, j) => (
                      <Skeleton key={j} className="h-20 w-full rounded-xl" />
                    ))}
                  </div>
                </div>
              ))}
            </div>
          ) : cats.length === 0 ? (
            <EmptyState
              icon={UtensilsCrossed}
              title="Your menu is empty"
              description="Start by creating a category, then add items to it."
              action={
                <Button
                  onClick={() => setCategoryDialog({ open: true, category: null })}
                >
                  <FolderPlus className="size-4" /> Create category
                </Button>
              }
            />
          ) : (
            <div className="space-y-8">
              {cats.map((category) => (
                <section key={category.id} className="space-y-3">
                  <div className="flex items-center gap-2">
                    <h2 className="text-lg font-semibold">{category.name}</h2>
                    <Badge variant="muted">
                      {category.menuItems?.length ?? 0}
                    </Badge>
                    {!category.isActive && (
                      <Badge variant="warning">Inactive</Badge>
                    )}
                    <div className="ml-auto flex items-center gap-1">
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() =>
                          setItemDialog({
                            open: true,
                            item: null,
                            categoryId: category.id,
                          })
                        }
                      >
                        <Plus className="size-4" /> Add item
                      </Button>
                      <DropdownMenu>
                        <DropdownMenuTrigger asChild>
                          <Button
                            variant="ghost"
                            size="icon-sm"
                            aria-label="Category actions"
                          >
                            <MoreVertical className="size-4" />
                          </Button>
                        </DropdownMenuTrigger>
                        <DropdownMenuContent align="end">
                          <DropdownMenuItem
                            onClick={() =>
                              setCategoryDialog({ open: true, category })
                            }
                          >
                            <Pencil className="size-4" /> Edit category
                          </DropdownMenuItem>
                          <DropdownMenuItem
                            variant="destructive"
                            onClick={() => setDeletingCat(category)}
                          >
                            <Trash2 className="size-4" /> Delete category
                          </DropdownMenuItem>
                        </DropdownMenuContent>
                      </DropdownMenu>
                    </div>
                  </div>

                  {category.menuItems && category.menuItems.length > 0 ? (
                    <div className="grid gap-3 md:grid-cols-2">
                      {category.menuItems.map((item) => (
                        <MenuItemCard
                          key={item.id}
                          item={item}
                          onEdit={(it) =>
                            setItemDialog({ open: true, item: it })
                          }
                        />
                      ))}
                    </div>
                  ) : (
                    <p className="text-muted-foreground rounded-lg border border-dashed px-4 py-6 text-center text-sm">
                      No items in this category yet.
                    </p>
                  )}
                </section>
              ))}
            </div>
          )}
        </TabsContent>

        <TabsContent value="addons" className="pt-4">
          <AddonsManager />
        </TabsContent>
      </Tabs>

      <ItemFormDialog
        open={itemDialog.open}
        onOpenChange={(o) => setItemDialog((s) => ({ ...s, open: o }))}
        categories={cats}
        defaultCategoryId={itemDialog.categoryId}
        item={itemDialog.item}
      />
      <CategoryFormDialog
        open={categoryDialog.open}
        onOpenChange={(o) => setCategoryDialog((s) => ({ ...s, open: o }))}
        category={categoryDialog.category}
      />
      <ConfirmDialog
        open={!!deletingCat}
        onOpenChange={(o) => !o && setDeletingCat(null)}
        title="Delete category?"
        description={
          deletingCat
            ? `"${deletingCat.name}" and its items will be removed.`
            : ""
        }
        confirmLabel="Delete"
        destructive
        pending={delCategory.isPending}
        onConfirm={() =>
          deletingCat &&
          delCategory.mutate(deletingCat.id, {
            onSuccess: () => setDeletingCat(null),
          })
        }
      />
    </div>
  );
}
