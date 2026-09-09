import { notFound } from "next/navigation";

import { Gallery } from "./gallery";

export const metadata = {
  title: "Design system — Wasabi",
  robots: { index: false, follow: false },
};

/** Internal reference only; never shipped to customers. */
export default function DesignSystemPage() {
  if (process.env.NODE_ENV === "production") notFound();
  return <Gallery />;
}
