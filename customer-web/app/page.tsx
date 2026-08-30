import { TopBar } from "@/components/landing/top-bar";
import { LandingNav } from "@/components/landing/landing-nav";
import { LandingHero } from "@/components/landing/landing-hero";
import { FeaturedMenu } from "@/components/landing/deals";
import { Categories } from "@/components/landing/categories";
import { BrandStory } from "@/components/landing/brand-story";
import { FulfillmentOptions } from "@/components/landing/app-promo";
import { HowItWorks } from "@/components/landing/how-it-works";
import { LandingFooter } from "@/components/landing/landing-footer";
import { MobileBottomNav } from "@/components/mobile-bottom-nav";

export default function LandingPage() {
  return (
    <div className="wasabi-app-shell min-h-dvh">
      <div className="hidden sm:block">
        <TopBar />
      </div>
      <LandingNav />
      <main>
        <LandingHero />
        <FeaturedMenu />
        <BrandStory />
        <Categories />
        <HowItWorks />
        <FulfillmentOptions />
      </main>
      <LandingFooter />
      <MobileBottomNav />
    </div>
  );
}
