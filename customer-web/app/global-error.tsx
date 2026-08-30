"use client";

export default function GlobalError({ reset }: { error: Error & { digest?: string }; reset: () => void }) {
  return (
    <html lang="en">
      <body style={{ margin: 0, fontFamily: "system-ui, sans-serif", background: "#fff9f5", color: "#181615" }}>
        <main style={{ minHeight: "100vh", display: "grid", placeItems: "center", padding: 24, textAlign: "center" }}>
          <div>
            <h1>Wasabi couldn&apos;t load</h1>
            <p>Please check your connection and try again.</p>
            <button onClick={reset} style={{ marginTop: 16, minHeight: 48, padding: "0 24px", border: 0, borderRadius: 12, background: "#d21f3c", color: "white", fontWeight: 700 }}>Try again</button>
          </div>
        </main>
      </body>
    </html>
  );
}
