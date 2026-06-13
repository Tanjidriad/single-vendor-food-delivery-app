"use client";

import { useState } from "react";
import {
  Store,
  Bell,
  Clock,
  Printer,
  Volume2,
  Palette,
  Shield,
  HelpCircle,
  ChevronRight,
  Check,
  Moon,
  Sun,
  Vibrate,
} from "lucide-react";
import { cn } from "@/lib/utils";
import { Switch } from "@/components/ui/switch";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";

interface SettingsSectionProps {
  title: string;
  children: React.ReactNode;
}

function SettingsSection({ title, children }: SettingsSectionProps) {
  return (
    <div className="space-y-2">
      <h3 className="text-xs font-semibold text-muted-foreground uppercase tracking-wider px-1">
        {title}
      </h3>
      <div className="bg-card border border-border rounded-xl divide-y divide-border overflow-hidden">
        {children}
      </div>
    </div>
  );
}

interface SettingsRowProps {
  icon: React.ReactNode;
  label: string;
  description?: string;
  action?: React.ReactNode;
  onClick?: () => void;
}

function SettingsRow({ icon, label, description, action, onClick }: SettingsRowProps) {
  const Wrapper = onClick ? "button" : "div";

  return (
    <Wrapper
      onClick={onClick}
      className={cn(
        "w-full flex items-center gap-3 p-3 md:p-4",
        onClick && "hover:bg-secondary/50 transition-colors text-left"
      )}
    >
      <div className="w-9 h-9 rounded-lg bg-secondary flex items-center justify-center flex-shrink-0">
        {icon}
      </div>
      <div className="flex-1 min-w-0">
        <div className="font-medium text-foreground text-sm">{label}</div>
        {description && (
          <div className="text-xs text-muted-foreground mt-0.5 truncate">{description}</div>
        )}
      </div>
      {action || (onClick && <ChevronRight className="w-5 h-5 text-muted-foreground flex-shrink-0" />)}
    </Wrapper>
  );
}

export function Settings() {
  const [notifications, setNotifications] = useState(true);
  const [soundEnabled, setSoundEnabled] = useState(true);
  const [vibration, setVibration] = useState(true);
  const [autoPrint, setAutoPrint] = useState(false);
  const [darkMode, setDarkMode] = useState(true);
  const [prepTimeTarget, setPrepTimeTarget] = useState("15");

  return (
    <div className="flex-1 flex flex-col min-h-0 p-3 md:p-6 overflow-y-auto pb-20 md:pb-6">
      {/* Header */}
      <div className="mb-4 md:mb-6">
        <h1 className="text-xl md:text-2xl font-bold text-foreground">Settings</h1>
        <p className="text-sm text-muted-foreground mt-1">Manage your kitchen preferences</p>
      </div>

      <div className="space-y-4 md:space-y-6 max-w-2xl">
        {/* Store Settings */}
        <SettingsSection title="Store">
          <SettingsRow
            icon={<Store className="w-5 h-5 text-kds-info" />}
            label="Store Information"
            description="Burger Palace - 123 Main St"
            onClick={() => {}}
          />
          <SettingsRow
            icon={<Clock className="w-5 h-5 text-kds-warning" />}
            label="Operating Hours"
            description="11:00 AM - 10:00 PM"
            onClick={() => {}}
          />
          <div className="p-3 md:p-4 flex items-center gap-3">
            <div className="w-9 h-9 rounded-lg bg-secondary flex items-center justify-center flex-shrink-0">
              <Clock className="w-5 h-5 text-kds-success" />
            </div>
            <div className="flex-1 min-w-0">
              <div className="font-medium text-foreground text-sm">Prep Time Target</div>
              <div className="text-xs text-muted-foreground mt-0.5">Target minutes per order</div>
            </div>
            <div className="flex items-center gap-2">
              <Input
                type="number"
                value={prepTimeTarget}
                onChange={(e) => setPrepTimeTarget(e.target.value)}
                className="w-16 h-8 text-center bg-secondary border-border"
              />
              <span className="text-sm text-muted-foreground">min</span>
            </div>
          </div>
        </SettingsSection>

        {/* Notifications */}
        <SettingsSection title="Notifications">
          <SettingsRow
            icon={<Bell className="w-5 h-5 text-kds-urgent" />}
            label="Push Notifications"
            description="New order alerts"
            action={
              <Switch
                checked={notifications}
                onCheckedChange={setNotifications}
                className="data-[state=checked]:bg-kds-success"
              />
            }
          />
          <SettingsRow
            icon={<Volume2 className="w-5 h-5 text-kds-info" />}
            label="Sound Alerts"
            description="Audio for new orders"
            action={
              <Switch
                checked={soundEnabled}
                onCheckedChange={setSoundEnabled}
                className="data-[state=checked]:bg-kds-success"
              />
            }
          />
          <SettingsRow
            icon={<Vibrate className="w-5 h-5 text-kds-warning" />}
            label="Vibration"
            description="Haptic feedback"
            action={
              <Switch
                checked={vibration}
                onCheckedChange={setVibration}
                className="data-[state=checked]:bg-kds-success"
              />
            }
          />
        </SettingsSection>

        {/* Hardware */}
        <SettingsSection title="Hardware">
          <SettingsRow
            icon={<Printer className="w-5 h-5 text-muted-foreground" />}
            label="Printer Setup"
            description="Star TSP143III"
            onClick={() => {}}
          />
          <SettingsRow
            icon={<Printer className="w-5 h-5 text-kds-success" />}
            label="Auto-Print Orders"
            description="Print tickets automatically"
            action={
              <Switch
                checked={autoPrint}
                onCheckedChange={setAutoPrint}
                className="data-[state=checked]:bg-kds-success"
              />
            }
          />
        </SettingsSection>

        {/* Appearance */}
        <SettingsSection title="Appearance">
          <SettingsRow
            icon={darkMode ? <Moon className="w-5 h-5 text-kds-info" /> : <Sun className="w-5 h-5 text-kds-warning" />}
            label="Dark Mode"
            description="Optimized for kitchen visibility"
            action={
              <Switch
                checked={darkMode}
                onCheckedChange={setDarkMode}
                className="data-[state=checked]:bg-kds-success"
              />
            }
          />
          <SettingsRow
            icon={<Palette className="w-5 h-5 text-kds-success" />}
            label="Display Theme"
            description="Default theme"
            onClick={() => {}}
          />
        </SettingsSection>

        {/* Support */}
        <SettingsSection title="Support">
          <SettingsRow
            icon={<Shield className="w-5 h-5 text-kds-info" />}
            label="Privacy & Security"
            onClick={() => {}}
          />
          <SettingsRow
            icon={<HelpCircle className="w-5 h-5 text-muted-foreground" />}
            label="Help & Support"
            description="Contact us or view FAQ"
            onClick={() => {}}
          />
        </SettingsSection>

        {/* App Info */}
        <div className="text-center py-4 text-xs text-muted-foreground">
          <p>Kitchen Display System v2.1.0</p>
          <p className="mt-1">Built with care for restaurant teams</p>
        </div>
      </div>
    </div>
  );
}
