"use client";

import { useRef, useState } from "react";
import { ImagePlus, Loader2, X } from "lucide-react";
import { toast } from "sonner";

import { uploadImage } from "@/lib/api/upload";
import { ApiError } from "@/lib/api/client";
import { cn } from "@/lib/utils";

interface ImageUploadProps {
  value?: string | null;
  onChange: (url: string | null) => void;
  className?: string;
}

export function ImageUpload({ value, onChange, className }: ImageUploadProps) {
  const inputRef = useRef<HTMLInputElement>(null);
  const [uploading, setUploading] = useState(false);

  const handleFile = async (file: File) => {
    if (!file.type.startsWith("image/")) {
      toast.error("Please choose an image file");
      return;
    }
    if (file.size > 5 * 1024 * 1024) {
      toast.error("Image must be under 5 MB");
      return;
    }
    setUploading(true);
    try {
      const res = await uploadImage(file);
      onChange(res.url);
    } catch (e) {
      toast.error(e instanceof ApiError ? e.message : "Upload failed");
    } finally {
      setUploading(false);
    }
  };

  return (
    <div className={cn("flex items-center gap-3", className)}>
      <div className="bg-muted relative size-20 shrink-0 overflow-hidden rounded-lg border">
        {value ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img src={value} alt="" className="size-full object-cover" />
        ) : (
          <div className="text-muted-foreground flex size-full items-center justify-center">
            <ImagePlus className="size-6" />
          </div>
        )}
        {uploading && (
          <div className="bg-background/70 absolute inset-0 flex items-center justify-center">
            <Loader2 className="size-5 animate-spin" />
          </div>
        )}
      </div>
      <div className="space-y-1.5">
        <button
          type="button"
          disabled={uploading}
          onClick={() => inputRef.current?.click()}
          className="border-input hover:bg-accent inline-flex h-8 items-center rounded-md border px-3 text-sm font-medium disabled:opacity-50"
        >
          {value ? "Replace" : "Upload image"}
        </button>
        {value && (
          <button
            type="button"
            onClick={() => onChange(null)}
            className="text-muted-foreground hover:text-destructive ml-2 inline-flex h-8 items-center gap-1 text-sm"
          >
            <X className="size-3.5" /> Remove
          </button>
        )}
        <p className="text-muted-foreground text-xs">PNG or JPG, up to 5 MB</p>
      </div>
      <input
        ref={inputRef}
        type="file"
        accept="image/*"
        className="hidden"
        onChange={(e) => {
          const file = e.target.files?.[0];
          if (file) handleFile(file);
          e.target.value = "";
        }}
      />
    </div>
  );
}
