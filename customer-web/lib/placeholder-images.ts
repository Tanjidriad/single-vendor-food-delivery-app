// Curated placeholder food photography (public/img). These are temporary
// stand-ins that look premium; real photos arrive via the backend (Cloudinary)
// and take precedence anywhere an item already has an imageUrl.
export const FOOD_PHOTOS = [
  "/img/momo-steamed.jpg",
  "/img/momo-chili.jpg",
  "/img/momo-bowl.jpg",
  "/img/momo-shumai.jpg",
  "/img/hero.jpg",
] as const;

export const HERO_PHOTO = "/img/hero.jpg";

/** Deterministically pick a placeholder photo from a stable seed (e.g. item id
    or name) so a given item always shows the same image. */
export function placeholderFood(seed: string): string {
  let h = 0;
  for (let i = 0; i < seed.length; i++) h = (h * 31 + seed.charCodeAt(i)) | 0;
  return FOOD_PHOTOS[Math.abs(h) % FOOD_PHOTOS.length];
}
