import { cn } from "@/lib/utils";

/** Wasabi wordmark: EN + JP (芥末) with a small torii mark. */
export function Wordmark({ className }: { className?: string }) {
  return (
    <span className={cn("inline-flex items-center gap-2", className)}>
      <ToriiMark className="h-4 w-[18px] text-[var(--brand)]" />
      <span className="font-display text-[22px] font-black leading-none tracking-tight text-[var(--foreground)]">
        Wasabi
      </span>
      <span className="text-[15px] font-bold text-[var(--brand)]">芥末</span>
    </span>
  );
}

export function ToriiMark({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 32 28" fill="none" className={className} aria-hidden="true">
      <path
        d="M2 6h28M4 9h24"
        stroke="currentColor"
        strokeWidth="3"
        strokeLinecap="round"
      />
      <path
        d="M8 9v18M24 9v18"
        stroke="currentColor"
        strokeWidth="3.4"
        strokeLinecap="round"
      />
    </svg>
  );
}

/** Hand-drawn momo (dumpling) illustration — used as an appetizing
    fallback when a real photo isn't available yet. */
export function MomoGlyph({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 120 100" className={className} aria-hidden="true">
      <defs>
        <radialGradient id="momoBody" cx="50%" cy="30%" r="80%">
          <stop offset="0%" stopColor="#FFF6E2" />
          <stop offset="70%" stopColor="#F3DCA6" />
          <stop offset="100%" stopColor="#E8C983" />
        </radialGradient>
      </defs>
      <ellipse cx="60" cy="86" rx="40" ry="7" fill="rgba(120,80,20,.14)" />
      <path
        d="M60 30c22 0 34 14 34 30 0 12-14 22-34 22S26 72 26 60c0-16 12-30 34-30Z"
        fill="url(#momoBody)"
      />
      <path
        d="M32 56c6-5 10-5 14 0m-8 0c6-5 10-5 14 0m-6 0c6-5 10-5 14 0m-6 0c6-5 10-5 14 0m-6 0c6-5 10-5 14 0"
        stroke="#DBBE7C"
        strokeWidth="2.4"
        strokeLinecap="round"
        fill="none"
        opacity=".8"
      />
      <circle cx="60" cy="40" r="7" fill="#FFFBEE" opacity=".7" />
    </svg>
  );
}
