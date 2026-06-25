"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { Eye, EyeOff, Loader2, UtensilsCrossed } from "lucide-react";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { useAuth, useLogin } from "@/lib/auth/use-auth";

export default function LoginPage() {
  const router = useRouter();
  const { isAuthenticated, hydrated } = useAuth();
  const login = useLogin();

  const [emailOrPhone, setEmailOrPhone] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);

  // Bounce already-authenticated users to the dashboard.
  useEffect(() => {
    if (hydrated && isAuthenticated) router.replace("/");
  }, [hydrated, isAuthenticated, router]);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    login.mutate({ emailOrPhone, password });
  };

  const errorMessage =
    login.error instanceof Error ? login.error.message : null;

  return (
    <div className="grid min-h-screen lg:grid-cols-2">
      {/* Brand panel */}
      <div className="bg-primary text-primary-foreground relative hidden flex-col justify-between overflow-hidden p-12 lg:flex">
        <div
          className="absolute inset-0 opacity-20"
          style={{
            backgroundImage:
              "radial-gradient(circle at 20% 20%, rgba(255,255,255,0.5) 0, transparent 45%), radial-gradient(circle at 80% 60%, rgba(0,0,0,0.3) 0, transparent 40%)",
          }}
        />
        <div className="relative flex items-center gap-3">
          <div className="bg-white/15 flex size-11 items-center justify-center rounded-xl backdrop-blur">
            <UtensilsCrossed className="size-6" />
          </div>
          <span className="text-lg font-semibold">Food Admin</span>
        </div>
        <div className="relative space-y-4">
          <h1 className="text-4xl font-semibold leading-tight">
            Run your restaurant,
            <br />
            beautifully.
          </h1>
          <p className="max-w-md text-base text-primary-foreground/80">
            Orders, menu, riders, promotions, and finance — one fast, focused
            console built for operations teams.
          </p>
        </div>
        <p className="relative text-sm text-primary-foreground/70">
          © {new Date().getFullYear()} Food Delivery · Operations Console
        </p>
      </div>

      {/* Form panel */}
      <div className="flex items-center justify-center p-6 sm:p-12">
        <div className="w-full max-w-sm space-y-8">
          <div className="space-y-2 lg:hidden">
            <div className="bg-primary text-primary-foreground mb-4 flex size-11 items-center justify-center rounded-xl">
              <UtensilsCrossed className="size-6" />
            </div>
          </div>

          <div className="space-y-1.5">
            <h2 className="text-2xl font-semibold tracking-tight">
              Welcome back
            </h2>
            <p className="text-muted-foreground text-sm">
              Sign in to your admin account to continue.
            </p>
          </div>

          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="emailOrPhone">Email or phone</Label>
              <Input
                id="emailOrPhone"
                type="text"
                autoComplete="username"
                placeholder="you@restaurant.com"
                value={emailOrPhone}
                onChange={(e) => setEmailOrPhone(e.target.value)}
                required
                autoFocus
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="password">Password</Label>
              <div className="relative">
                <Input
                  id="password"
                  type={showPassword ? "text" : "password"}
                  autoComplete="current-password"
                  placeholder="••••••••"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  required
                  className="pr-10"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword((v) => !v)}
                  className="text-muted-foreground hover:text-foreground absolute inset-y-0 right-0 flex items-center px-3"
                  aria-label={showPassword ? "Hide password" : "Show password"}
                >
                  {showPassword ? (
                    <EyeOff className="size-4" />
                  ) : (
                    <Eye className="size-4" />
                  )}
                </button>
              </div>
            </div>

            {errorMessage && (
              <p
                role="alert"
                className="bg-destructive/10 text-destructive rounded-md px-3 py-2 text-sm"
              >
                {errorMessage}
              </p>
            )}

            <Button
              type="submit"
              className="w-full"
              size="lg"
              disabled={login.isPending}
            >
              {login.isPending && <Loader2 className="size-4 animate-spin" />}
              Sign in
            </Button>
          </form>

          <p className="text-muted-foreground text-center text-xs">
            Staff access only. Customer and rider accounts cannot sign in here.
          </p>
        </div>
      </div>
    </div>
  );
}
