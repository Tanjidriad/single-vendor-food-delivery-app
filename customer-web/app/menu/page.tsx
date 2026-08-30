import { CartBar } from "@/components/cart-bar";
import { MobileBottomNav } from "@/components/mobile-bottom-nav";
import { InfoBlock } from "@/components/menu/info-block";
import { MenuBrowser } from "@/components/menu/menu-browser";
import { MenuHeader } from "@/components/menu/menu-header";
import { MenuFooter } from "@/components/menu/menu-footer";
import { MenuMotionProvider } from "@/components/menu/menu-motion-provider";
import { PromoSlider } from "@/components/menu/promo-slider";
import { RestaurantHero } from "@/components/menu/restaurant-hero";
import { Reviews } from "@/components/menu/reviews";

export default function MenuPage() {
  return (
    <MenuMotionProvider>
      <div className="wasabi-menu-shell min-h-dvh">
        <MenuHeader />
        <main>
          <RestaurantHero />
          <PromoSlider />
          <MenuBrowser />
          <div className="mt-8 border-t-4 border-[var(--menu-ink)] pb-8 sm:mt-2">
            <InfoBlock />
            <Reviews />
          </div>
        </main>
        <div className="pb-[calc(3.75rem+env(safe-area-inset-bottom))] sm:pb-0"><MenuFooter /></div>
        <CartBar />
        <MobileBottomNav />
      </div>
    </MenuMotionProvider>
  );
}
