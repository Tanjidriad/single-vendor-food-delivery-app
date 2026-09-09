import { api } from "@/lib/api/client";
import { endpoints } from "@/lib/api/endpoints";
import type { UploadResult } from "@/types";

/** Uploads an image file (multipart) and returns the Cloudinary URL. */
export async function uploadImage(file: File): Promise<UploadResult> {
  const form = new FormData();
  form.append("file", file);
  return api.post<UploadResult>(endpoints.uploads.image, form, { raw: true });
}
