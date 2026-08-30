"use client";

import { motion } from "framer-motion";
import { ArrowRight, Clock, Flame } from "lucide-react";

import { MomoGlyph, ToriiMark } from "@/components/brand";

const ease = [0.16, 1, 0.3, 1] as const;

export function Hero() {
  return (
    <section className="relative mx-auto max-w-[1280px] px-4 pt-6 sm:px-6 lg:px-10 lg:pt-10">
      <div className="grain relative overflow-hidden rounded-[16px] bg-[var(--ink)] px-6 py-12 text-[var(--on-ink)] sm:rounded-[20px] sm:px-12 sm:py-16 lg:px-16 lg:py-20">
        {/* decorative torii watermark */}
        <ToriiMark className="pointer-events-none absolute -right-6 -top-6 h-48 w-52 text-[var(--brand)] opacity-[0.14] sm:h-72 sm:w-80" />

        <div className="relative grid items-center gap-10 lg:grid-cols-[1.15fr_0.85fr]">
          <div>
            <motion.p
              initial={{ opacity: 0, y: 12 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5, ease }}
              className="mb-5 inline-flex items-center gap-2 rounded-full border border-white/15 bg-white/5 px-3.5 py-1.5 text-[11px] font-semibold uppercase tracking-[0.18em] text-[var(--mustard)]"
            >
              <Flame className="h-3.5 w-3.5" /> Hand-folded · Steamed to order
            </motion.p>

            <motion.h1
              initial={{ opacity: 0, y: 16 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6, ease, delay: 0.05 }}
              className="font-display text-[clamp(2.75rem,7vw,5.5rem)] font-black leading-[0.92] tracking-[-0.01em] text-balance"
            >
              Momos,
              <br />
              made to <span className="text-[var(--brand)]">order.</span>
            </motion.h1>

            <motion.p
              initial={{ opacity: 0, y: 16 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6, ease, delay: 0.12 }}
              className="mt-5 max-w-[46ch] text-[15px] leading-relaxed text-white/70 sm:text-[17px]"
            >
              Eight fillings, five sauces, one very serious dumpling. Steamed
              fresh and delivered hot across Dhaka.
            </motion.p>

            <motion.div
              initial={{ opacity: 0, y: 16 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6, ease, delay: 0.18 }}
              className="mt-8 flex flex-wrap items-center gap-3"
            >
              <a
                href="#menu"
                className="group inline-flex h-[56px] items-center gap-2 rounded-[12px] bg-[var(--brand)] px-7 text-base font-semibold text-white transition-[background-color,transform] duration-150 hover:bg-[var(--brand-hover)] active:scale-[0.98]"
              >
                Start your order
                <ArrowRight className="h-4 w-4 transition-transform group-hover:translate-x-0.5" />
              </a>
              <span className="inline-flex items-center gap-2 text-sm text-white/60">
                <Clock className="h-4 w-4" /> ~30–45 min delivery
              </span>
            </motion.div>
          </div>

          {/* hero food composition */}
          <motion.div
            initial={{ opacity: 0, scale: 0.9, rotate: -4 }}
            animate={{ opacity: 1, scale: 1, rotate: 0 }}
            transition={{ duration: 0.7, ease, delay: 0.1 }}
            className="relative mx-auto hidden aspect-square w-full max-w-[360px] lg:block"
          >
            <div className="absolute inset-0 rounded-full bg-[var(--brand)]/90" />
            <div className="absolute inset-3 rounded-full bg-gradient-to-br from-[#FFF4DC] to-[#EFCF92]" />
            <MomoGlyph className="absolute inset-0 m-auto h-3/4 w-3/4 drop-shadow-xl" />
            <span className="absolute -right-2 top-6 grid h-20 w-20 rotate-12 place-items-center rounded-full bg-[var(--mustard)] text-center font-display text-sm font-black leading-none text-[#3a2600]">
              ৳150<br />
              <span className="text-[10px] font-bold">from</span>
            </span>
          </motion.div>
        </div>
      </div>
    </section>
  );
}
