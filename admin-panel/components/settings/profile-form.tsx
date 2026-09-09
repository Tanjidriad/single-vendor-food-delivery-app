"use client";

import { useEffect, useState } from "react";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import {
  Card,
  CardContent,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Spinner } from "@/components/common/spinner";
import { ImageUpload } from "@/components/common/image-upload";
import { useUpdateProfile } from "@/lib/api/queries/settings";
import type { RestaurantDetail } from "@/types";

export function ProfileForm({ restaurant }: { restaurant?: RestaurantDetail }) {
  const update = useUpdateProfile();
  const [form, setForm] = useState({
    name: "",
    description: "",
    phone: "",
    email: "",
    addressLine: "",
    city: "",
    country: "",
  });
  const [logoUrl, setLogoUrl] = useState<string | null>(null);

  useEffect(() => {
    if (!restaurant) return;
    setForm({
      name: restaurant.name ?? "",
      description: restaurant.description ?? "",
      phone: restaurant.phone ?? "",
      email: restaurant.email ?? "",
      addressLine: restaurant.addressLine ?? "",
      city: restaurant.city ?? "",
      country: restaurant.country ?? "",
    });
    setLogoUrl(restaurant.logoUrl ?? null);
  }, [restaurant]);

  const set = (k: keyof typeof form) => (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) =>
    setForm((f) => ({ ...f, [k]: e.target.value }));

  return (
    <Card>
      <CardHeader className="border-b">
        <CardTitle>Restaurant profile</CardTitle>
        <CardDescription>
          Public details shown to customers in the app.
        </CardDescription>
      </CardHeader>
      <CardContent className="space-y-4 pt-6">
        <div className="space-y-2">
          <Label>Logo</Label>
          <ImageUpload value={logoUrl} onChange={setLogoUrl} />
        </div>
        <div className="grid gap-4 sm:grid-cols-2">
          <div className="space-y-2">
            <Label htmlFor="r-name">Name</Label>
            <Input id="r-name" value={form.name} onChange={set("name")} />
          </div>
          <div className="space-y-2">
            <Label htmlFor="r-phone">Phone</Label>
            <Input id="r-phone" value={form.phone} onChange={set("phone")} />
          </div>
        </div>
        <div className="space-y-2">
          <Label htmlFor="r-desc">Description</Label>
          <Textarea
            id="r-desc"
            value={form.description}
            onChange={set("description")}
          />
        </div>
        <div className="grid gap-4 sm:grid-cols-2">
          <div className="space-y-2">
            <Label htmlFor="r-email">Email</Label>
            <Input id="r-email" type="email" value={form.email} onChange={set("email")} />
          </div>
          <div className="space-y-2">
            <Label htmlFor="r-addr">Address</Label>
            <Input id="r-addr" value={form.addressLine} onChange={set("addressLine")} />
          </div>
          <div className="space-y-2">
            <Label htmlFor="r-city">City</Label>
            <Input id="r-city" value={form.city} onChange={set("city")} />
          </div>
          <div className="space-y-2">
            <Label htmlFor="r-country">Country</Label>
            <Input id="r-country" value={form.country} onChange={set("country")} />
          </div>
        </div>
      </CardContent>
      <CardFooter className="border-t">
        <Button
          className="ml-auto"
          disabled={update.isPending}
          onClick={() =>
            update.mutate({
              ...form,
              email: form.email || undefined,
              logoUrl: logoUrl || undefined,
            })
          }
        >
          {update.isPending && <Spinner />}
          Save profile
        </Button>
      </CardFooter>
    </Card>
  );
}
