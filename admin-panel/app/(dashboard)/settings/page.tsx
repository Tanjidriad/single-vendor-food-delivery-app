"use client";

import { PageHeader } from "@/components/common/page-header";
import { ErrorState } from "@/components/common/error-state";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { ProfileForm } from "@/components/settings/profile-form";
import { BusinessForm } from "@/components/settings/business-form";
import { DeliveryForm } from "@/components/settings/delivery-form";
import { HoursForm } from "@/components/settings/hours-form";
import { ZonesManager } from "@/components/settings/zones-manager";
import { useRestaurant } from "@/lib/api/queries/settings";

export default function SettingsPage() {
  const { data, isError, refetch } = useRestaurant();

  return (
    <div className="space-y-6">
      <PageHeader
        title="Settings"
        description="Configure your restaurant profile, pricing, hours, and delivery."
      />

      {isError ? (
        <ErrorState
          message="Couldn't load restaurant settings."
          onRetry={() => refetch()}
        />
      ) : (
        <Tabs defaultValue="profile">
          <TabsList className="flex-wrap">
            <TabsTrigger value="profile">Profile</TabsTrigger>
            <TabsTrigger value="business">Business</TabsTrigger>
            <TabsTrigger value="delivery">Delivery</TabsTrigger>
            <TabsTrigger value="hours">Hours</TabsTrigger>
            <TabsTrigger value="zones">Zones</TabsTrigger>
          </TabsList>

          <TabsContent value="profile" className="pt-4">
            <ProfileForm restaurant={data} />
          </TabsContent>
          <TabsContent value="business" className="pt-4">
            <BusinessForm restaurant={data} />
          </TabsContent>
          <TabsContent value="delivery" className="pt-4">
            <DeliveryForm restaurant={data} />
          </TabsContent>
          <TabsContent value="hours" className="pt-4">
            <HoursForm restaurant={data} />
          </TabsContent>
          <TabsContent value="zones" className="pt-4">
            <ZonesManager />
          </TabsContent>
        </Tabs>
      )}
    </div>
  );
}
