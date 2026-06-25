"use client";

import { useState } from "react";
import {
  ImageIcon,
  MoreVertical,
  Pencil,
  Plus,
  Tag,
  Trash2,
} from "lucide-react";

import { PageHeader } from "@/components/common/page-header";
import { ErrorState } from "@/components/common/error-state";
import { EmptyState } from "@/components/common/empty-state";
import { ConfirmDialog } from "@/components/common/confirm-dialog";
import { BannerFormDialog } from "@/components/promotions/banner-form-dialog";
import { CouponFormDialog } from "@/components/promotions/coupon-form-dialog";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Card } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import {
  useBanners,
  useCoupons,
  useDeleteBanner,
  useDeleteCoupon,
} from "@/lib/api/queries/promotions";
import { formatCurrency, formatDate } from "@/lib/utils";
import type { Banner, Coupon } from "@/types";

export default function PromotionsPage() {
  return (
    <div className="space-y-6">
      <PageHeader
        title="Promotions"
        description="Run banners and discount coupons to drive orders."
      />
      <Tabs defaultValue="banners">
        <TabsList>
          <TabsTrigger value="banners">Banners</TabsTrigger>
          <TabsTrigger value="coupons">Coupons</TabsTrigger>
        </TabsList>
        <TabsContent value="banners" className="pt-4">
          <BannersTab />
        </TabsContent>
        <TabsContent value="coupons" className="pt-4">
          <CouponsTab />
        </TabsContent>
      </Tabs>
    </div>
  );
}

function BannersTab() {
  const { data, isLoading, isError, refetch } = useBanners();
  const del = useDeleteBanner();
  const [dialog, setDialog] = useState<{ open: boolean; banner?: Banner | null }>({
    open: false,
  });
  const [deleting, setDeleting] = useState<Banner | null>(null);

  return (
    <div className="space-y-4">
      <div className="flex justify-end">
        <Button onClick={() => setDialog({ open: true, banner: null })}>
          <Plus className="size-4" /> New banner
        </Button>
      </div>

      {isError ? (
        <ErrorState message="Couldn't load banners." onRetry={() => refetch()} />
      ) : isLoading ? (
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {Array.from({ length: 3 }).map((_, i) => (
            <Skeleton key={i} className="h-44 w-full rounded-xl" />
          ))}
        </div>
      ) : !data?.length ? (
        <EmptyState
          icon={ImageIcon}
          title="No banners yet"
          description="Promote offers with eye-catching banners in the customer app."
          action={
            <Button onClick={() => setDialog({ open: true, banner: null })}>
              <Plus className="size-4" /> Create banner
            </Button>
          }
        />
      ) : (
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {data.map((banner) => (
            <Card key={banner.id} className="gap-0 overflow-hidden p-0">
              <div className="bg-muted relative aspect-[16/7]">
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img
                  src={banner.imageUrl}
                  alt={banner.title}
                  className="size-full object-cover"
                />
                {!banner.isActive && (
                  <Badge variant="muted" className="absolute top-2 left-2">
                    Inactive
                  </Badge>
                )}
              </div>
              <div className="flex items-center gap-2 p-3">
                <p className="min-w-0 flex-1 truncate font-medium">
                  {banner.title}
                </p>
                <CardMenu
                  onEdit={() => setDialog({ open: true, banner })}
                  onDelete={() => setDeleting(banner)}
                />
              </div>
            </Card>
          ))}
        </div>
      )}

      <BannerFormDialog
        open={dialog.open}
        onOpenChange={(o) => setDialog((s) => ({ ...s, open: o }))}
        banner={dialog.banner}
      />
      <ConfirmDialog
        open={!!deleting}
        onOpenChange={(o) => !o && setDeleting(null)}
        title="Delete banner?"
        description={deleting ? `"${deleting.title}" will be removed.` : ""}
        confirmLabel="Delete"
        destructive
        pending={del.isPending}
        onConfirm={() =>
          deleting && del.mutate(deleting.id, { onSuccess: () => setDeleting(null) })
        }
      />
    </div>
  );
}

function CouponsTab() {
  const { data, isLoading, isError, refetch } = useCoupons();
  const del = useDeleteCoupon();
  const [dialog, setDialog] = useState<{ open: boolean; coupon?: Coupon | null }>({
    open: false,
  });
  const [deleting, setDeleting] = useState<Coupon | null>(null);

  return (
    <div className="space-y-4">
      <div className="flex justify-end">
        <Button onClick={() => setDialog({ open: true, coupon: null })}>
          <Plus className="size-4" /> New coupon
        </Button>
      </div>

      {isError ? (
        <ErrorState message="Couldn't load coupons." onRetry={() => refetch()} />
      ) : isLoading ? (
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {Array.from({ length: 3 }).map((_, i) => (
            <Skeleton key={i} className="h-32 w-full rounded-xl" />
          ))}
        </div>
      ) : !data?.length ? (
        <EmptyState
          icon={Tag}
          title="No coupons yet"
          description="Create discount codes to reward customers and boost sales."
          action={
            <Button onClick={() => setDialog({ open: true, coupon: null })}>
              <Plus className="size-4" /> Create coupon
            </Button>
          }
        />
      ) : (
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {data.map((coupon) => (
            <Card key={coupon.id} className="gap-3 p-4">
              <div className="flex items-start justify-between">
                <div className="bg-primary/10 text-primary inline-flex items-center gap-1.5 rounded-md px-2 py-1 font-mono text-sm font-semibold">
                  <Tag className="size-3.5" />
                  {coupon.code}
                </div>
                <CardMenu
                  onEdit={() => setDialog({ open: true, coupon })}
                  onDelete={() => setDeleting(coupon)}
                />
              </div>
              <p className="text-2xl font-semibold">
                {coupon.discountType === "PERCENT"
                  ? `${coupon.discountValue}% off`
                  : `${formatCurrency(coupon.discountValue)} off`}
              </p>
              <div className="text-muted-foreground flex flex-wrap items-center gap-x-3 gap-y-1 text-xs">
                {coupon.minOrderAmount ? (
                  <span>Min {formatCurrency(coupon.minOrderAmount)}</span>
                ) : null}
                {coupon.maxUses ? (
                  <span>
                    {coupon.usedCount}/{coupon.maxUses} used
                  </span>
                ) : (
                  <span>{coupon.usedCount} used</span>
                )}
                {coupon.endsAt && <span>Ends {formatDate(coupon.endsAt)}</span>}
              </div>
              <div className="flex flex-wrap items-center gap-1.5">
                <Badge variant={coupon.isActive ? "success" : "muted"}>
                  {coupon.isActive ? "Active" : "Inactive"}
                </Badge>
                {coupon.targetUserId ? (
                  <Badge variant="info">
                    For {coupon.targetCustomer?.email ||
                      coupon.targetCustomer?.phone ||
                      "1 customer"}
                  </Badge>
                ) : coupon.newCustomersOnly ? (
                  <Badge variant="info">New customers</Badge>
                ) : null}
                {coupon.perUserLimit ? (
                  <Badge variant="secondary">
                    {coupon.perUserLimit}/customer
                  </Badge>
                ) : null}
              </div>
            </Card>
          ))}
        </div>
      )}

      <CouponFormDialog
        open={dialog.open}
        onOpenChange={(o) => setDialog((s) => ({ ...s, open: o }))}
        coupon={dialog.coupon}
      />
      <ConfirmDialog
        open={!!deleting}
        onOpenChange={(o) => !o && setDeleting(null)}
        title="Delete coupon?"
        description={deleting ? `"${deleting.code}" will be removed.` : ""}
        confirmLabel="Delete"
        destructive
        pending={del.isPending}
        onConfirm={() =>
          deleting && del.mutate(deleting.id, { onSuccess: () => setDeleting(null) })
        }
      />
    </div>
  );
}

function CardMenu({
  onEdit,
  onDelete,
}: {
  onEdit: () => void;
  onDelete: () => void;
}) {
  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button variant="ghost" size="icon-sm" aria-label="Actions">
          <MoreVertical className="size-4" />
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end">
        <DropdownMenuItem onClick={onEdit}>
          <Pencil className="size-4" /> Edit
        </DropdownMenuItem>
        <DropdownMenuItem variant="destructive" onClick={onDelete}>
          <Trash2 className="size-4" /> Delete
        </DropdownMenuItem>
      </DropdownMenuContent>
    </DropdownMenu>
  );
}
