"use client";

import { useState } from "react";
import Link from "next/link";
import { toast } from "sonner";
import {
  Bell,
  Heart,
  Home,
  LifeBuoy,
  Loader2,
  LogOut,
  MapPin,
  Package,
  Pencil,
  Phone,
  Plus,
  Trash2,
  UserRound,
} from "lucide-react";


import { TopBar } from "@/components/landing/top-bar";
import { LandingNav } from "@/components/landing/landing-nav";
import { LandingFooter } from "@/components/landing/landing-footer";
import { MobileBottomNav } from "@/components/mobile-bottom-nav";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { useAuth, useLogout, useMe, useUpdateProfile } from "@/lib/auth/use-auth";
import {
  useAddresses,
  useCreateAddress,
  useDeleteAddress,
  type AddressInput,
} from "@/lib/api/queries/addresses";
import { geocodeAddress } from "@/lib/api/queries/checkout";
import { ApiError } from "@/lib/api/client";
import type { Address, AddressLabel } from "@/types";

export default function AccountPage() {
  const { isAuthenticated, hydrated, user } = useAuth();
  useMe();
  const logout = useLogout();
  const { data: addresses, isLoading: addressesLoading } = useAddresses();
  const createAddress = useCreateAddress();
  const deleteAddress = useDeleteAddress();
  const updateProfile = useUpdateProfile();
  const [adding, setAdding] = useState(false);
  const [editingProfile, setEditingProfile] = useState(false);
  const [profileName, setProfileName] = useState("");

  if (hydrated && !isAuthenticated) {
    return (
      <Shell>
        <div className="mx-auto flex max-w-md flex-col items-center px-4 py-24 text-center">
          <span className="grid h-16 w-16 place-items-center bg-[var(--menu-red)] text-white">
            <UserRound className="h-7 w-7" />
          </span>
          <h1 className="font-street mt-5 text-3xl">
            Sign in to your account
          </h1>
          <p className="mt-2 text-sm text-[var(--foreground-dim)]">
            Manage saved addresses and see your order history.
          </p>
          <Link href="/login?next=/account" className="mt-6">
            <Button size="lg">Sign in</Button>
          </Link>
        </div>
      </Shell>
    );
  }

  return (
    <Shell>
      <div className="mx-auto max-w-[980px] px-4 py-10 sm:px-6 sm:py-16 lg:py-20">
        <p className="wasabi-page-kicker">
          Account
        </p>
        <h1 className="font-street mt-4 text-[clamp(3rem,9vw,6.8rem)] leading-[0.82]">
          {user?.fullName || "Your account"}
        </h1>

        {/* Profile */}
        <section className="mt-10 border-2 border-[var(--menu-ink)] bg-[var(--menu-rice)] p-5 sm:p-7">
          <div className="flex items-center justify-between gap-3">
            <h2 className="font-street text-xl">Profile slip</h2>
            {!editingProfile && (
              <Button
                variant="light"
                size="sm"
                onClick={() => {
                  setProfileName(user?.fullName ?? "");
                  setEditingProfile(true);
                }}
              >
                <Pencil className="h-4 w-4" /> Edit name
              </Button>
            )}
          </div>
          {editingProfile && (
            <form
              className="mt-4 flex flex-col gap-2 sm:flex-row"
              onSubmit={(event) => {
                event.preventDefault();
                updateProfile.mutate(
                  { fullName: profileName.trim() },
                  {
                    onSuccess: () => {
                      toast.success("Profile updated.");
                      setEditingProfile(false);
                    },
                    onError: (error) =>
                      toast.error(
                        error instanceof ApiError
                          ? error.message
                          : "Couldn't update your profile."
                      ),
                  }
                );
              }}
            >
              <Input
                aria-label="Full name"
                value={profileName}
                onChange={(event) => setProfileName(event.target.value)}
                minLength={2}
                maxLength={80}
                required
              />
              <div className="flex gap-2">
                <Button type="submit" size="sm" disabled={updateProfile.isPending}>Save</Button>
                <Button type="button" size="sm" variant="ghost" onClick={() => setEditingProfile(false)}>Cancel</Button>
              </div>
            </form>
          )}
          <dl className="mt-4 space-y-3 text-sm">
            {user?.fullName && (
              <div className="flex items-center gap-3">
                <UserRound className="h-4 w-4 text-[var(--brand)]" />
                <div>
                  <dt className="text-xs font-semibold text-[var(--foreground-mute)]">
                    Name
                  </dt>
                  <dd className="font-semibold">{user.fullName}</dd>
                </div>
              </div>
            )}
            {user?.phone && (
              <div className="flex items-center gap-3">
                <Phone className="h-4 w-4 text-[var(--brand)]" />
                <div>
                  <dt className="text-xs font-semibold text-[var(--foreground-mute)]">
                    Phone
                  </dt>
                  <dd className="font-semibold">{user.phone}</dd>
                </div>
              </div>
            )}
            {user?.email && (
              <div className="flex items-center gap-3">
                <Home className="h-4 w-4 text-[var(--brand)]" />
                <div>
                  <dt className="text-xs font-semibold text-[var(--foreground-mute)]">
                    Email
                  </dt>
                  <dd className="font-semibold">{user.email}</dd>
                </div>
              </div>
            )}
          </dl>

          <div className="mt-5 flex flex-wrap gap-3 border-t border-[var(--border-subtle)] pt-5">
            <Link href="/orders">
              <Button variant="light" size="sm">
                <Package className="h-4 w-4" /> My orders
              </Button>
            </Link>
            <Link href="/favorites">
              <Button variant="light" size="sm">
                <Heart className="h-4 w-4" /> Favorites
              </Button>
            </Link>
            <Link href="/notifications">
              <Button variant="light" size="sm">
                <Bell className="h-4 w-4" /> Notifications
              </Button>
            </Link>
            <Link href="/support">
              <Button variant="light" size="sm">
                <LifeBuoy className="h-4 w-4" /> Support
              </Button>
            </Link>
            <Button variant="ghost" size="sm" onClick={logout}>
              <LogOut className="h-4 w-4" /> Sign out
            </Button>
          </div>

        </section>

        {/* Addresses */}
        <section className="mt-6 border-2 border-[var(--menu-ink)] bg-[var(--menu-tan)] p-5 sm:p-7">
          <div className="flex items-center justify-between gap-3">
            <h2 className="font-street text-xl">Delivery stops</h2>
            {!adding && (
              <Button
                variant="light"
                size="sm"
                onClick={() => setAdding(true)}
              >
                <Plus className="h-4 w-4" /> Add
              </Button>
            )}
          </div>

          {addressesLoading && (
            <div className="flex justify-center py-10">
              <Loader2 className="h-6 w-6 animate-spin text-[var(--foreground-mute)]" />
            </div>
          )}

          {!addressesLoading && (addresses?.length ?? 0) === 0 && !adding && (
            <p className="mt-4 text-sm text-[var(--foreground-dim)]">
              No saved addresses yet. Add one for faster checkout.
            </p>
          )}

          <ul className="mt-4 space-y-3">
            {(addresses ?? []).map((a) => (
              <AddressRow
                key={a.id}
                address={a}
                onDelete={() =>
                  deleteAddress.mutate(a.id, {
                    onSuccess: () => toast.success("Address removed."),
                    onError: (e) =>
                      toast.error(
                        e instanceof ApiError ? e.message : "Couldn't delete."
                      ),
                  })
                }
                deleting={deleteAddress.isPending}
              />
            ))}
          </ul>

          {adding && (
            <AddAddressForm
              pending={createAddress.isPending}
              onCancel={() => setAdding(false)}
              onSubmit={(input) =>
                createAddress.mutate(input, {
                  onSuccess: () => {
                    toast.success("Address saved.");
                    setAdding(false);
                  },
                  onError: (e) =>
                    toast.error(
                      e instanceof ApiError ? e.message : "Couldn't save address."
                    ),
                })
              }
            />
          )}
        </section>
      </div>
    </Shell>
  );
}

function AddressRow({
  address,
  onDelete,
  deleting,
}: {
  address: Address;
  onDelete: () => void;
  deleting: boolean;
}) {
  const text = [address.line1, address.line2, address.city]
    .filter(Boolean)
    .join(", ");

  return (
    <li className="flex items-start gap-3 border border-black/20 bg-[var(--menu-rice)] p-3.5 dark:border-white/20">
      <MapPin className="mt-0.5 h-4 w-4 flex-none text-[var(--brand)]" />
      <div className="min-w-0 flex-1">
        <p className="text-sm font-semibold capitalize">
          {address.label.toLowerCase()}
          {address.isDefault && (
            <span className="ml-2 rounded-full bg-[var(--surface-sunken)] px-2 py-0.5 text-[10px] font-bold uppercase tracking-wider text-[var(--foreground-mute)]">
              Default
            </span>
          )}
        </p>
        <p className="mt-0.5 text-[13px] text-[var(--foreground-dim)]">{text}</p>
      </div>
      <button
        aria-label="Delete address"
        onClick={onDelete}
        disabled={deleting}
        className="grid h-8 w-8 flex-none place-items-center rounded-full text-[var(--foreground-mute)] transition-colors hover:bg-[var(--surface-sunken)] hover:text-[var(--brand)]"
      >
        <Trash2 className="h-4 w-4" />
      </button>
    </li>
  );
}

function AddAddressForm({
  onSubmit,
  onCancel,
  pending,
}: {
  onSubmit: (input: AddressInput) => void;
  onCancel: () => void;
  pending: boolean;
}) {
  const [label, setLabel] = useState<AddressLabel>("HOME");
  const [line1, setLine1] = useState("");
  const [line2, setLine2] = useState("");
  const [city, setCity] = useState("Dhaka");
  const [finding, setFinding] = useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!line1.trim()) return;
    setFinding(true);
    try {
      const query = [line1, line2, city].filter(Boolean).join(", ");
      const geo = await geocodeAddress(query);
      onSubmit({
        label,
        line1: line1.trim(),
        line2: line2.trim() || undefined,
        city: city.trim() || undefined,
        latitude: geo.latitude,
        longitude: geo.longitude,
        isDefault: true,
      });
    } catch {
      toast.error("Couldn't locate that address. Add more detail.");
    } finally {
      setFinding(false);
    }
  }

  return (
    <form
      onSubmit={handleSubmit}
      className="mt-4 space-y-3 border border-black/20 bg-[var(--menu-rice)] p-4 dark:border-white/20"
    >
      <div className="flex gap-2">
        {(["HOME", "OFFICE", "OTHER"] as AddressLabel[]).map((l) => (
          <button
            key={l}
            type="button"
            onClick={() => setLabel(l)}
            className={`rounded-full px-3.5 py-1.5 text-xs font-bold capitalize transition-colors ${
              label === l
                ? "bg-[var(--brand)] text-white"
                : "bg-[var(--surface)] text-[var(--foreground-dim)]"
            }`}
          >
            {l.toLowerCase()}
          </button>
        ))}
      </div>
      <Input
        value={line1}
        onChange={(e) => setLine1(e.target.value)}
        placeholder="House, road, area"
        className="h-11"
        required
      />
      <Input
        value={line2}
        onChange={(e) => setLine2(e.target.value)}
        placeholder="Apartment, landmark (optional)"
        className="h-11"
      />
      <Input
        value={city}
        onChange={(e) => setCity(e.target.value)}
        placeholder="City"
        className="h-11"
      />
      <div className="flex gap-2">
        <Button
          type="submit"
          size="sm"
          disabled={pending || finding || !line1.trim()}
        >
          {pending || finding ? (
            <>
              <Loader2 className="h-4 w-4 animate-spin" /> Saving…
            </>
          ) : (
            "Save address"
          )}
        </Button>
        <Button type="button" variant="ghost" size="sm" onClick={onCancel}>
          Cancel
        </Button>
      </div>
    </form>
  );
}

function Shell({ children }: { children: React.ReactNode }) {
  return (
    <div className="wasabi-app-shell min-h-dvh">
      <div className="hidden sm:block">
        <TopBar />
      </div>
      <LandingNav />
      <main>
        {children}
      </main>
      <LandingFooter />
      <MobileBottomNav />
    </div>
  );
}
