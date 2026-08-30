const STATS = [
  { value: "50,000+", label: "Momos served" },
  { value: "30–45 min", label: "Avg delivery" },
  { value: "4.8★", label: "Customer rating" },
  { value: "8", label: "Momo varieties" },
];

export function Stats() {
  return (
    <section className="mx-auto max-w-[1440px] px-4 pt-16 sm:px-6 lg:px-10">
      <div className="grid grid-cols-2 gap-px overflow-hidden rounded-[16px] bg-[var(--brand)] text-white lg:grid-cols-4">
        {STATS.map((s) => (
          <div key={s.label} className="bg-[var(--brand)] px-6 py-8 text-center">
            <p className="font-display text-[clamp(1.8rem,3.5vw,2.6rem)] font-black leading-none">
              {s.value}
            </p>
            <p className="mt-2 text-sm text-white/80">{s.label}</p>
          </div>
        ))}
      </div>
    </section>
  );
}
