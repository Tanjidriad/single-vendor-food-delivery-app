"use client";

import { PageHeader } from "@/components/common/page-header";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { ReportsTab } from "@/components/finance/reports-tab";
import { ComplaintsTab } from "@/components/finance/complaints-tab";
import { SettlementsTab } from "@/components/finance/settlements-tab";

export default function FinancePage() {
  return (
    <div className="space-y-6">
      <PageHeader
        title="Finance"
        description="Reports, complaints, and cash settlements."
      />
      <Tabs defaultValue="reports">
        <TabsList>
          <TabsTrigger value="reports">Reports</TabsTrigger>
          <TabsTrigger value="complaints">Complaints</TabsTrigger>
          <TabsTrigger value="settlements">Settlements</TabsTrigger>
        </TabsList>
        <TabsContent value="reports" className="pt-4">
          <ReportsTab />
        </TabsContent>
        <TabsContent value="complaints" className="pt-4">
          <ComplaintsTab />
        </TabsContent>
        <TabsContent value="settlements" className="pt-4">
          <SettlementsTab />
        </TabsContent>
      </Tabs>
    </div>
  );
}
