"use client";

import { motion } from "framer-motion";
import { Bike, MapPinned, Utensils } from "lucide-react";

const STEPS = [
  {
    icon: Utensils,
    title: "Choose your food",
    body: "Explore available dishes, options, and add-ons from the Wasabi menu.",
  },
  {
    icon: MapPinned,
    title: "Choose your way",
    body: "Select delivery to your address or pickup directly from Wasabi.",
  },
  {
    icon: Bike,
    title: "Follow the order",
    body: "See each kitchen and delivery status as your order moves forward.",
  },
];

export function HowItWorks() {
  return (
    <section
      id="how-it-works"
      className="mx-auto max-w-[1440px] scroll-mt-24 px-4 pt-20 sm:px-6 sm:pt-28 lg:px-10"
    >
      <div className="grain relative overflow-hidden border-l-8 border-[var(--menu-red)] bg-[var(--menu-bar)] px-6 py-10 text-white sm:px-10 sm:py-14 lg:px-14 lg:py-16">
        <div className="pointer-events-none absolute -right-20 -top-24 font-display text-[18rem] font-black leading-none text-white/[0.025]">
          3
        </div>
        <div className="relative">
          <p className="text-[11px] font-black uppercase tracking-[0.18em] text-[var(--menu-red)]">
            Order route
          </p>
          <h2 className="font-street mt-3 max-w-[11ch] text-[clamp(2.6rem,8vw,5.4rem)] leading-[0.86]">
            From menu to your door
          </h2>
          <p className="mt-4 max-w-[52ch] text-sm leading-6 text-white/60 sm:text-[15px]">
            One clear flow from choosing a dish to following its progress.
            Delivery and pickup are built into the same experience.
          </p>

          <div className="relative mt-10 grid gap-0 md:grid-cols-3 md:gap-8 lg:mt-14">
            <div className="absolute left-6 top-6 hidden h-px w-[calc(100%-3rem)] bg-white/15 md:block" />
            {STEPS.map((step, index) => (
              <motion.article
                key={step.title}
                initial={{ opacity: 0, y: 14 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true, margin: "-60px" }}
                transition={{
                  duration: 0.5,
                  ease: [0.16, 1, 0.3, 1],
                  delay: index * 0.08,
                }}
                className="relative grid grid-cols-[48px_1fr] gap-4 border-b border-white/10 py-6 first:pt-0 last:border-b-0 last:pb-0 md:block md:border-b-0 md:py-0"
              >
                <span className="relative z-10 grid h-12 w-12 place-items-center border border-white/20 bg-[var(--menu-red)] text-white">
                  <step.icon className="h-5 w-5" />
                </span>
                <div className="md:mt-7">
                  <p className="text-[10px] font-bold uppercase tracking-[0.18em] text-white/35">
                    Step 0{index + 1}
                  </p>
                  <h3 className="mt-1 text-base font-bold text-white sm:text-lg">
                    {step.title}
                  </h3>
                  <p className="mt-2 max-w-[32ch] text-sm leading-6 text-white/55">
                    {step.body}
                  </p>
                </div>
              </motion.article>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
