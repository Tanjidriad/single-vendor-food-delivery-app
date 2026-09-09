"use client";

import { useState } from "react";
import Image from "next/image";

import { placeholderFood } from "@/lib/placeholder-images";
import { cn } from "@/lib/utils";

/**
 * Product image. Real photos come from the backend (Cloudinary) via `src`;
 * when absent or broken we fall back to a curated placeholder food photo
 * (deterministic by `alt`) so the layout always shows something appetizing.
 */
export function FoodImage({
  src,
  alt,
  className,
  sizes,
  loading,
}: {
  src?: string | null;
  alt: string;
  className?: string;
  sizes?: string;
  loading?: "eager" | "lazy";
}) {
  const [failed, setFailed] = useState(false);
  const resolved = !src || failed ? placeholderFood(alt) : src;

  return (
    <div
      className={cn(
        "relative overflow-hidden bg-gradient-to-br from-[#FFF4DC] to-[#F0D9A8]",
        className
      )}
    >
      <Image
        src={resolved}
        alt={alt}
        fill
        sizes={sizes ?? "(max-width: 768px) 40vw, 320px"}
        loading={loading}
        className="object-cover"
        onError={() => setFailed(true)}
      />
    </div>
  );
}
