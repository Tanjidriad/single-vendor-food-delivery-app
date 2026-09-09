"use client";

import { useState } from "react";
import Link from "next/link";
import { ArrowLeft, CheckCircle2, KeyRound, Loader2 } from "lucide-react";
import { toast } from "sonner";

import { Wordmark } from "@/components/brand";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { ApiError } from "@/lib/api/client";
import { toBangladeshE164 } from "@/lib/auth/phone";
import {
  useResetPassword,
  useSendPasswordResetOtp,
} from "@/lib/auth/use-auth";

type Stage = "request" | "reset" | "done";

function messageOf(error: unknown, fallback: string) {
  return error instanceof ApiError ? error.message : fallback;
}

export default function ForgotPasswordPage() {
  const [stage, setStage] = useState<Stage>("request");
  const [identifier, setIdentifier] = useState("");
  const [code, setCode] = useState("");
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const sendOtp = useSendPasswordResetOtp();
  const resetPassword = useResetPassword();

  const identity = identifier.includes("@")
    ? { email: identifier.trim().toLowerCase() }
    : { phone: toBangladeshE164(identifier) };

  function requestCode() {
    sendOtp.mutate(identity, {
      onSuccess: () => {
        setStage("reset");
        toast.success("If that account exists, a reset code has been sent.");
      },
      onError: (error) =>
        toast.error(messageOf(error, "Could not send a reset code.")),
    });
  }

  function reset() {
    if (password !== confirmPassword) {
      toast.error("Passwords do not match.");
      return;
    }
    resetPassword.mutate(
      { ...identity, code, newPassword: password },
      {
        onSuccess: () => setStage("done"),
        onError: (error) =>
          toast.error(messageOf(error, "Could not reset your password.")),
      }
    );
  }

  return (
    <main className="wasabi-app-shell grid min-h-dvh place-items-center bg-[var(--menu-rice)] px-4 py-10">
      <section className="w-full max-w-[430px] border-2 border-[var(--menu-ink)] bg-[var(--menu-rice)] p-6 sm:p-8">
        <div className="flex items-center justify-between gap-4">
          <Link
            href="/login"
            aria-label="Back to sign in"
            className="grid h-11 w-11 place-items-center border-2 border-[var(--menu-ink)] transition-colors hover:bg-[var(--menu-red)] hover:text-white"
          >
            <ArrowLeft className="h-5 w-5" />
          </Link>
          <Wordmark />
        </div>

        {stage === "done" ? (
          <div className="py-8 text-center">
            <CheckCircle2 className="mx-auto h-12 w-12 text-[var(--brand)]" />
            <h1 className="font-street mt-5 text-3xl">
              Password updated
            </h1>
            <p className="mt-2 text-sm leading-6 text-[var(--foreground-dim)]">
              You can now sign in using your new password.
            </p>
            <Link href="/login" className="mt-6 block">
              <Button size="lg" className="w-full">
                Return to sign in
              </Button>
            </Link>
          </div>
        ) : (
          <>
            <span className="mt-8 grid h-12 w-12 place-items-center bg-[var(--menu-red)] text-white">
              <KeyRound className="h-5 w-5" />
            </span>
            <h1 className="font-street mt-5 text-4xl">
              Reset password
            </h1>
            <p className="mt-2 text-sm leading-6 text-[var(--foreground-dim)]">
              {stage === "request"
                ? "Enter the phone number or email on your Wasabi account."
                : "Enter the six-digit code and choose a new password."}
            </p>

            <form
              className="mt-7 space-y-4"
              onSubmit={(event) => {
                event.preventDefault();
                if (stage === "request") requestCode();
                else reset();
              }}
            >
              <label className="block text-xs font-semibold text-[var(--foreground-dim)]">
                Email or phone
                <Input
                  className="mt-1.5 h-[54px]"
                  value={identifier}
                  onChange={(event) => setIdentifier(event.target.value)}
                  disabled={stage === "reset"}
                  required
                />
              </label>

              {stage === "reset" && (
                <>
                  <label className="block text-xs font-semibold text-[var(--foreground-dim)]">
                    Reset code
                    <Input
                      className="mt-1.5 h-[54px] text-center text-lg tracking-[0.4em]"
                      value={code}
                      onChange={(event) => setCode(event.target.value)}
                      inputMode="numeric"
                      minLength={6}
                      maxLength={6}
                      required
                      autoFocus
                    />
                  </label>
                  <label className="block text-xs font-semibold text-[var(--foreground-dim)]">
                    New password
                    <Input
                      className="mt-1.5 h-[54px]"
                      type="password"
                      value={password}
                      onChange={(event) => setPassword(event.target.value)}
                      minLength={8}
                      maxLength={64}
                      required
                    />
                  </label>
                  <label className="block text-xs font-semibold text-[var(--foreground-dim)]">
                    Confirm password
                    <Input
                      className="mt-1.5 h-[54px]"
                      type="password"
                      value={confirmPassword}
                      onChange={(event) => setConfirmPassword(event.target.value)}
                      minLength={8}
                      maxLength={64}
                      required
                    />
                  </label>
                </>
              )}

              <Button
                type="submit"
                size="lg"
                className="w-full"
                disabled={sendOtp.isPending || resetPassword.isPending}
              >
                {(sendOtp.isPending || resetPassword.isPending) && (
                  <Loader2 className="h-5 w-5 animate-spin" />
                )}
                {stage === "request" ? "Send reset code" : "Update password"}
              </Button>
            </form>
          </>
        )}
      </section>
    </main>
  );
}
