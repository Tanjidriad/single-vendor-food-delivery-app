import type { MetadataRoute } from "next";

export default function manifest(): MetadataRoute.Manifest {
  return {
    name: "Wasabi Momo House",
    short_name: "Wasabi",
    description: "Order Wasabi momo for delivery or pickup.",
    start_url: "/",
    display: "standalone",
    background_color: "#fff9f5",
    theme_color: "#d21f3c",
    orientation: "portrait-primary",
    icons: [{ src: "/icon.svg", sizes: "any", type: "image/svg+xml" }],
  };
}
