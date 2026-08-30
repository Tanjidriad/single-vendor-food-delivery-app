export default function Loading() {
  return (
    <main className="wasabi-app-shell min-h-dvh bg-[var(--menu-rice)] px-4 py-8" aria-busy="true" aria-label="Loading page">
      <div className="mx-auto max-w-[1100px] animate-pulse">
        <div className="h-10 w-36 rounded-xl bg-[var(--surface-sunken)]" />
        <div className="mt-12 h-10 w-3/4 max-w-xl rounded-xl bg-[var(--surface-sunken)]" />
        <div className="mt-4 h-5 w-1/2 max-w-md rounded-lg bg-[var(--surface-sunken)]" />
        <div className="mt-10 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {[0, 1, 2].map((item) => (
            <div key={item} className="h-56 rounded-[20px] bg-[var(--surface-sunken)]" />
          ))}
        </div>
      </div>
    </main>
  );
}
