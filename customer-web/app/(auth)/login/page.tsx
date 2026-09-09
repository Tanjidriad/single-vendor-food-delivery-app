"use client";

import { Suspense, useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { useSearchParams } from "next/navigation";
import { AnimatePresence, motion } from "framer-motion";
import { ArrowLeft, ArrowRight, KeyRound, Smartphone } from "lucide-react";
import { toast } from "sonner";

import { Wordmark, ToriiMark } from "@/components/brand";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { HERO_PHOTO } from "@/lib/placeholder-images";
import {
  useRegister,
  useSendOtp,
  usePasswordLogin,
  useVerifyOtp,
} from "@/lib/auth/use-auth";
import { ApiError } from "@/lib/api/client";
import { toBangladeshE164 } from "@/lib/auth/phone";

type View = "signin" | "signup";
type Method = "otp" | "password";

const ease = [0.16, 1, 0.3, 1] as const;

function errMessage(e: unknown, fallback: string) {
  return e instanceof ApiError ? e.message : fallback;
}

export default function LoginPage() {
  return (
    <Suspense fallback={<AuthShell />}>
      <AuthInner />
    </Suspense>
  );
}

/* ============================================================
   SHELL — editorial split: photo story | cream form
   ============================================================ */

function AuthShell({ children }: { children?: React.ReactNode }) {
  return (
    <main className="wasabi-app-shell flex min-h-dvh flex-col bg-[var(--menu-rice)] lg:grid lg:grid-cols-[minmax(0,1fr)_minmax(460px,44%)]">
      <StoryPanel />
      <section className="relative flex flex-1 items-center justify-center px-5 py-10 sm:px-10 lg:px-14">
        <div className="w-full max-w-[380px]">
          {children ?? (
            <div className="h-[420px] animate-pulse rounded-[24px] border border-[var(--border-subtle)] bg-[var(--surface)]" />
          )}
        </div>
      </section>
    </main>
  );
}

/** Left: editorial food photography as the hero, with a hand-drawn seal
    and an oversized display line. Collapses to a compact banner on mobile. */
function StoryPanel() {
  return (
    <aside className="relative isolate flex min-h-[38vh] flex-col justify-end overflow-hidden bg-[var(--ink)] px-6 pb-8 pt-6 text-white sm:px-10 lg:min-h-dvh lg:px-14 lg:pb-14 lg:pt-10">
      {/* Editorial photo — vivid, not dimmed */}
      <Image
        src={HERO_PHOTO}
        alt="Freshly steamed momo from Wasabi Momo House"
        fill
        priority
        sizes="(max-width: 1024px) 100vw, 56vw"
        className="-z-10 object-cover"
      />
      {/* Warm editorial scrim — reads text without muddying the food */}
      <div className="absolute inset-0 -z-10 bg-gradient-to-t from-[var(--ink)] via-[var(--ink)]/45 to-[var(--ink)]/10" />

      {/* --- TOP ROW: wordmark + seal --- */}
      <div className="absolute inset-x-6 top-6 flex items-start justify-between sm:inset-x-10 lg:inset-x-14 lg:top-10">
        <Link href="/" className="inline-flex">
          <Wordmark className="[&_.font-display]:text-white" />
        </Link>
        <Seal className="hidden h-20 w-20 text-white/90 lg:block" />
      </div>

      {/* --- BOTTOM: editorial display line --- */}
      <div className="relative max-w-[24ch]">
        <p className="mb-3 text-[11px] font-bold uppercase tracking-[0.28em] text-[color-mix(in_srgb,var(--brand)_75%,white)]">
          Wasabi Momo House
        </p>
        <h2 className="font-display text-[clamp(2rem,4.4vw,3.6rem)] font-black leading-[0.98] tracking-[-0.02em]">
          Great momo,
          <br />
          delivered warm.
        </h2>
        <p className="mt-4 hidden max-w-[36ch] text-[15px] leading-relaxed text-white/70 sm:block">
          Sign in to check out in seconds and follow every order from our
          kitchen to your door.
        </p>

        {/* Fine editorial credentials */}
        <div className="mt-6 hidden items-center gap-3 text-[13px] font-medium text-white/60 lg:flex">
          <span>Live tracking</span>
          <Dot />
          <span>Delivery &amp; pickup</span>
          <Dot />
          <span>One-tap reorder</span>
        </div>
      </div>
    </aside>
  );
}

function Dot() {
  return <span className="h-1 w-1 rounded-full bg-current opacity-50" />;
}

/** Hand-drawn circular seal — torii mark + 芥末, per the brand's
    Japanese street-food character. Rotated slightly for a stamped feel. */
function Seal({ className }: { className?: string }) {
  return (
    <span className={`grid -rotate-6 place-items-center ${className ?? ""}`}>
      <span className="relative grid h-full w-full place-items-center rounded-full border border-white/45">
        <span className="absolute inset-1 rounded-full border border-dashed border-white/25" />
        <ToriiMark className="h-5 w-6" />
        <span className="mt-0.5 text-[13px] font-bold leading-none">芥末</span>
      </span>
    </span>
  );
}

/* ============================================================
   FORM PANEL
   ============================================================ */

function AuthInner() {
  const searchParams = useSearchParams();
  const next = searchParams.get("next");
  const [view, setView] = useState<View>("signin");
  const [method, setMethod] = useState<Method>("otp");

  return (
    <AuthShell>
      <motion.div
        initial={{ opacity: 0, y: 12 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.45, ease }}
      >
        {/* --- EYEBROW + HEADING --- */}
        <p className="text-[11px] font-bold uppercase tracking-[0.26em] text-[var(--brand)]">
          {view === "signup" ? "Join Wasabi" : "Your account"}
        </p>
        <h1 className="mt-2 font-display text-[clamp(2rem,3vw,2.6rem)] font-black leading-[1.05] tracking-[-0.02em]">
          {view === "signup" ? "Create account" : "Welcome back"}
        </h1>

        {/* --- VIEW TABS (editorial underline) --- */}
        <div className="mt-7 flex gap-7 border-b border-[var(--border)]">
          {(
            [
              { k: "signin", label: "Sign in" },
              { k: "signup", label: "Create account" },
            ] as const
          ).map((t) => {
            const active = view === t.k;
            return (
              <button
                key={t.k}
                type="button"
                onClick={() => setView(t.k)}
                className={`relative -mb-px pb-3 text-sm font-semibold transition-colors ${
                  active
                    ? "text-[var(--foreground)]"
                    : "text-[var(--foreground-mute)] hover:text-[var(--foreground-dim)]"
                }`}
              >
                {t.label}
                {active && (
                  <motion.span
                    layoutId="authTab"
                    className="absolute inset-x-0 -bottom-px h-[2px] rounded-full bg-[var(--brand)]"
                    transition={{ type: "spring", stiffness: 480, damping: 38 }}
                  />
                )}
              </button>
            );
          })}
        </div>

        {/* --- METHOD SEGMENTED CONTROL (sign in only) --- */}
        {view === "signin" && (
          <div className="mt-6">
            <div
              role="tablist"
              aria-label="Sign-in method"
              className="relative grid grid-cols-2 rounded-[14px] border border-[var(--border)] bg-[var(--surface-sunken)] p-1"
            >
              <MethodSegment
                active={method === "otp"}
                onClick={() => setMethod("otp")}
                icon={Smartphone}
                label="Phone code"
              />
              <MethodSegment
                active={method === "password"}
                onClick={() => setMethod("password")}
                icon={KeyRound}
                label="Password"
              />
            </div>
            <p className="mt-2 px-1 text-xs leading-relaxed text-[var(--foreground-mute)]">
              {method === "otp"
                ? "We'll text a one-time code to your phone. No password needed."
                : "Sign in with the email or phone and password on your account."}
            </p>
          </div>
        )}

        {/* --- FORMS --- */}
        <div className="mt-6">
          <AnimatePresence mode="wait">
            <motion.div
              key={view === "signup" ? "signup" : method}
              initial={{ opacity: 0, y: 8 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -8 }}
              transition={{ duration: 0.22, ease }}
            >
              {view === "signup" ? (
                <RegisterForm next={next} />
              ) : method === "otp" ? (
                <OtpForm next={next} />
              ) : (
                <PasswordForm next={next} />
              )}
            </motion.div>
          </AnimatePresence>
        </div>

        {/* --- FOOTER LINK --- */}
        <p className="mt-8 text-center text-xs text-[var(--foreground-mute)]">
          <Link
            href="/menu"
            className="inline-flex items-center gap-1 font-semibold text-[var(--foreground-dim)] underline-offset-4 transition-colors hover:text-[var(--foreground)] hover:underline"
          >
            Keep browsing the menu
            <ArrowRight className="h-3.5 w-3.5" />
          </Link>
        </p>
      </motion.div>
    </AuthShell>
  );
}

function MethodSegment({
  active,
  onClick,
  icon: Icon,
  label,
}: {
  active: boolean;
  onClick: () => void;
  icon: typeof Smartphone;
  label: string;
}) {
  return (
    <button
      type="button"
      role="tab"
      aria-selected={active}
      onClick={onClick}
      className={`relative z-10 flex h-11 items-center justify-center gap-2 rounded-[10px] text-sm font-semibold transition-colors ${
        active
          ? "text-[var(--foreground)]"
          : "text-[var(--foreground-mute)] hover:text-[var(--foreground-dim)]"
      }`}
    >
      {active && (
        <motion.span
          layoutId="methodSegment"
          className="absolute inset-0 -z-10 rounded-[10px] bg-[var(--surface)] shadow-[var(--shadow-xs)]"
          transition={{ type: "spring", stiffness: 460, damping: 36 }}
        />
      )}
      <Icon
        className={`h-[18px] w-[18px] ${active ? "text-[var(--brand)]" : ""}`}
      />
      {label}
    </button>
  );
}

/* ============================================================
   FIELDS
   ============================================================ */

function Field({
  label,
  hint,
  children,
}: {
  label: string;
  hint?: string;
  children: React.ReactNode;
}) {
  return (
    <label className="block">
      <span className="text-xs font-semibold text-[var(--foreground-dim)]">
        {label}{" "}
        {hint && (
          <span className="font-normal text-[var(--foreground-mute)]">
            {hint}
          </span>
        )}
      </span>
      <div className="mt-1.5">{children}</div>
    </label>
  );
}

/* ============================================================
   FORMS — logic preserved exactly
   ============================================================ */

function OtpForm({ next }: { next: string | null }) {
  const [phone, setPhone] = useState("");
  const [code, setCode] = useState("");
  const [sent, setSent] = useState(false);
  const sendOtp = useSendOtp();
  const verifyOtp = useVerifyOtp(next);

  return (
    <form
      className="space-y-4"
      onSubmit={(e) => {
        e.preventDefault();
        if (!sent) {
          sendOtp.mutate(
            { phone: toBangladeshE164(phone) },
            {
              onSuccess: () => {
                setSent(true);
                toast.success("Code sent to your phone.");
              },
              onError: (e) => toast.error(errMessage(e, "Could not send code.")),
            }
          );
        } else {
          verifyOtp.mutate(
            { phone: toBangladeshE164(phone), code },
            { onError: (e) => toast.error(errMessage(e, "Invalid code.")) }
          );
        }
      }}
    >
      <Field label="Phone number">
        <Input
          className="h-[54px]"
          type="tel"
          placeholder="01XXXXXXXXX"
          value={phone}
          onChange={(e) => setPhone(e.target.value)}
          disabled={sent}
          required
        />
      </Field>

      {sent && (
        <Field label="Verification code" hint="sent by SMS">
          <Input
            className="h-[54px] text-center text-lg tracking-[0.5em]"
            inputMode="numeric"
            placeholder="••••"
            value={code}
            onChange={(e) => setCode(e.target.value)}
            required
            autoFocus
          />
        </Field>
      )}

      <Button
        type="submit"
        size="lg"
        className="w-full"
        disabled={sendOtp.isPending || verifyOtp.isPending}
      >
        {sent
          ? verifyOtp.isPending
            ? "Verifying…"
            : "Verify & continue"
          : sendOtp.isPending
            ? "Sending…"
            : "Send code"}
      </Button>

      {sent && (
        <button
          type="button"
          className="mx-auto flex items-center gap-1.5 text-xs font-semibold text-[var(--foreground-mute)] hover:text-[var(--foreground-dim)]"
          onClick={() => setSent(false)}
        >
          <ArrowLeft className="h-3.5 w-3.5" />
          Change number
        </button>
      )}
    </form>
  );
}

function PasswordForm({ next }: { next: string | null }) {
  const [emailOrPhone, setEmailOrPhone] = useState("");
  const [password, setPassword] = useState("");
  const login = usePasswordLogin(next);

  return (
    <form
      className="space-y-4"
      onSubmit={(e) => {
        e.preventDefault();
        // Normalize a phone to E.164 so it matches the value stored at
        // registration; leave emails untouched.
        const id = emailOrPhone.includes("@")
          ? emailOrPhone.trim()
          : toBangladeshE164(emailOrPhone);
        login.mutate(
          { emailOrPhone: id, password },
          { onError: (e) => toast.error(errMessage(e, "Sign in failed.")) }
        );
      }}
    >
      <Field label="Email or phone">
        <Input
          className="h-[54px]"
          value={emailOrPhone}
          onChange={(e) => setEmailOrPhone(e.target.value)}
          required
        />
      </Field>
      <Field label="Password">
        <Input
          className="h-[54px]"
          type="password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          required
        />
      </Field>
      <Button type="submit" size="lg" className="w-full" disabled={login.isPending}>
        {login.isPending ? "Signing in…" : "Sign in"}
      </Button>
      <Link
        href="/forgot-password"
        className="block text-center text-sm font-semibold text-[var(--brand)] hover:underline"
      >
        Forgot password?
      </Link>
    </form>
  );
}

function RegisterForm({ next }: { next: string | null }) {
  const [fullName, setFullName] = useState("");
  const [phone, setPhone] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const register = useRegister(next);

  return (
    <form
      className="space-y-4"
      onSubmit={(e) => {
        e.preventDefault();
        register.mutate(
          {
            fullName,
            phone: toBangladeshE164(phone),
            email: email || undefined,
            password,
          },
          { onError: (e) => toast.error(errMessage(e, "Could not create account.")) }
        );
      }}
    >
      <Field label="Full name">
        <Input
          className="h-[54px]"
          value={fullName}
          onChange={(e) => setFullName(e.target.value)}
          required
        />
      </Field>
      <Field label="Phone number">
        <Input
          className="h-[54px]"
          type="tel"
          placeholder="01XXXXXXXXX"
          value={phone}
          onChange={(e) => setPhone(e.target.value)}
          required
        />
      </Field>
      <Field label="Email" hint="(optional)">
        <Input
          className="h-[54px]"
          type="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
        />
      </Field>
      <Field label="Password" hint="at least 8 characters">
        <Input
          className="h-[54px]"
          type="password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          minLength={8}
          required
        />
      </Field>
      <Button type="submit" size="lg" className="w-full" disabled={register.isPending}>
        {register.isPending ? "Creating…" : "Create account"}
      </Button>
    </form>
  );
}
