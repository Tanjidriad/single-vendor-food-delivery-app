# Premium Food Delivery Web App — Master Design System Prompt

Use the **`frontend-design`** and **`ui-ux-pro-max`** skills to design and implement an ultra-premium, visually exceptional food delivery website or web application.

The project must look like a bespoke **$5,000+ digital product** created by a world-class creative agency. Every visual decision should feel intentional, refined, distinctive, responsive, and production-ready.

Focus entirely on the **visual design system, interface quality, responsiveness, typography, composition, motion, imagery, accessibility, and premium presentation**.

Do not define, invent, or describe product features, business logic, backend functionality, database structure, authentication flows, API behavior, or operational workflows.

---

## 1. Core Objective

Create a sophisticated food delivery interface that immediately feels:

- Premium
- Memorable
- Appetizing
- Modern
- Editorial
- Energetic
- Trustworthy
- Custom-designed
- Commercially valuable
- Highly polished

The visual quality must be strong enough that a client would confidently pay at least **$5,000 USD** for the design.

The interface must not resemble a generic restaurant template, basic marketplace, ordinary SaaS dashboard, or quickly generated AI website.

It should combine the visual character of:

- Premium restaurant branding
- Contemporary Japanese street-food packaging
- Luxury hospitality
- Editorial food photography
- Modern mobile applications
- Award-worthy digital experiences

Use the uploaded menu image as the main reference for the brand color direction and graphic personality.

---

## 2. Skill Instructions

### `ui-ux-pro-max`

Use this skill to establish:

- Visual hierarchy
- Design-system consistency
- Responsive behavior
- Accessibility
- Touch-target sizing
- Grid structure
- Component proportions
- Typography scaling
- Interaction states
- Mobile usability
- Interface clarity
- UX polish

### `frontend-design`

Use this skill to translate the design system into:

- Premium frontend composition
- Precise responsive layouts
- Refined styling
- Reusable design tokens
- High-quality visual components
- Smooth interactions
- Sophisticated motion
- Clean and maintainable styling
- Pixel-perfect implementation

Do not settle for the first acceptable result. Review and refine the interface until it feels deliberately art-directed.

---

## 3. Creative Direction

The design language should be inspired by the uploaded food menu, especially its:

- Deep red branding
- Warm cream background
- Charcoal-black typography
- Bold graphic compositions
- Japanese visual influence
- Hand-drawn food illustrations
- Organic background patterns
- Irregular shapes
- Strong promotional typography
- Energetic food presentation

Elevate these characteristics into a refined digital experience.

The interface should feel inspired by premium Japanese food packaging and contemporary restaurant branding, but it must not look like a direct copy of a printed menu.

The final result should balance:

- Boldness and elegance
- Energy and clarity
- Warmth and sophistication
- Expressive branding and usability
- Strong visual identity and restraint

---

## 4. Brand Personality

The visual identity should communicate:

- Premium food quality
- Warm hospitality
- Urban energy
- Freshness
- Convenience
- Confidence
- Craftsmanship
- Cultural character
- Curated taste
- Reliable service

The brand must feel youthful and energetic without becoming childish.

It should feel luxurious without relying on gold, excessive decoration, or generic luxury clichés.

---

## 5. Color System

Use the uploaded menu as the primary color reference.

The main brand color must be a rich, confident red. Avoid bright orange-red, pink-red, neon red, or corporate crimson.

### Core Brand Colors

```css
--color-primary-50: #FBEDEE;
--color-primary-100: #F5D7D9;
--color-primary-200: #EBB2B6;
--color-primary-300: #DD858B;
--color-primary-400: #CF565E;
--color-primary-500: #B62329;
--color-primary-600: #A11E24;
--color-primary-700: #86181E;
--color-primary-800: #70151A;
--color-primary-900: #591116;

--color-brand-primary: #B62329;
```

### Neutral Colors

```css
--color-cream-50: #FFFDFC;
--color-cream-100: #FFF9F5;
--color-cream-200: #F7F2ED;
--color-cream-300: #F0E9E3;
--color-cream-400: #E6DDD5;

--color-charcoal-900: #181615;
--color-charcoal-800: #272321;
--color-charcoal-700: #3E3936;
--color-charcoal-600: #59524E;
--color-charcoal-500: #6D6661;
--color-charcoal-400: #9B918B;
--color-charcoal-300: #BDB4AE;
--color-charcoal-200: #DED4CC;
--color-charcoal-100: #EBE4DE;
```

### Supporting Accent Colors

```css
--color-mustard: #D9A22B;
--color-coral: #C76365;
--color-olive: #596043;
--color-success: #46715A;
--color-warning: #C88A32;
--color-error: #A91D25;
```

### Color Distribution

Use approximately:

- 55–65% warm cream and neutral surfaces
- 15–25% primary red
- 10–15% charcoal and black
- No more than 5% supporting accents

The red must feel dominant and memorable without overwhelming the interface.

Use warm cream as the main background instead of pure white.

Use charcoal for typography, icons, strong dividers, and high-contrast surfaces.

Use mustard, olive, and coral only for small highlights.

### Red Surface Rules

When using red as a large background:

- Use white or warm cream text
- Maintain strong contrast
- Add subtle grain or texture
- Keep the layout spacious
- Avoid glossy gradients
- Avoid strong drop shadows
- Do not place multiple competing accent colors on the red surface

---

## 6. Typography System

Typography must feel editorial, confident, premium, and highly legible.

Use an expressive display typeface for major headings and a clean modern sans-serif for body text and interface labels.

### Display Typeface Direction

Use one premium display family with:

- Strong personality
- Editorial proportions
- Slightly condensed or high-contrast construction
- Excellent large-size rendering
- Distinctive but readable letterforms

Suitable directions include:

- Contemporary editorial serif
- Refined display grotesk
- High-contrast modern serif
- Bold condensed display face

### Interface Typeface Direction

Use a neutral sans-serif with:

- Excellent mobile readability
- Clear numerals
- Multiple weights
- Clean punctuation
- Compact but comfortable proportions

Use no more than two primary font families.

### Responsive Type Scale

```css
--font-display-xl: clamp(3.5rem, 7vw, 6rem);
--font-display-lg: clamp(2.75rem, 5vw, 4.5rem);
--font-h1: clamp(2.25rem, 4vw, 3.5rem);
--font-h2: clamp(1.875rem, 3vw, 2.75rem);
--font-h3: clamp(1.375rem, 2vw, 1.875rem);
--font-h4: clamp(1.125rem, 1.5vw, 1.375rem);

--font-body-lg: clamp(1.0625rem, 1.2vw, 1.25rem);
--font-body: 1rem;
--font-body-sm: 0.875rem;
--font-caption: 0.75rem;
```

### Typography Rules

- Use tight line-height for large display headings
- Use comfortable line-height for body text
- Keep body text between 45 and 75 characters per line
- Use semibold weights for important labels
- Use uppercase sparingly
- Use italic styling only as an editorial accent
- Avoid excessive bold text
- Avoid mixing too many weights
- Use tabular numerals where visual alignment matters
- Use red to emphasize selected words, not entire paragraphs

Recommended line heights:

```css
--leading-display: 0.92;
--leading-heading: 1.08;
--leading-body: 1.6;
--leading-compact: 1.3;
```

---

## 7. Grid and Layout System

Use a disciplined responsive grid, but avoid making the interface feel rigid or repetitive.

### Desktop

- Maximum content width: 1440px
- Comfortable content width: 1280px
- 12-column grid
- Gutter: 24–32px
- Outer margin: 64–96px
- Large section spacing: 96–160px

### Tablet

- 8-column grid
- Gutter: 20–24px
- Outer margin: 32–48px
- Section spacing: 72–112px

### Mobile

- 4-column grid
- Gutter: 16px
- Side padding: 16–24px
- Section spacing: 56–88px
- No horizontal overflow
- No compressed desktop layouts

### Layout Principles

- Combine contained layouts with full-width visual moments
- Use asymmetry where it improves visual interest
- Avoid centering every section
- Avoid repeating identical card grids
- Create clear visual rhythm
- Use intentional negative space
- Allow imagery and typography to overlap selectively
- Maintain alignment even in expressive compositions
- Keep mobile layouts clean and easy to scan

Every major composition should feel individually art-directed.

---

## 8. Spacing System

Use an 8-point foundation with smaller intermediate values for precision.

```css
--space-1: 4px;
--space-2: 8px;
--space-3: 12px;
--space-4: 16px;
--space-5: 20px;
--space-6: 24px;
--space-8: 32px;
--space-10: 40px;
--space-12: 48px;
--space-16: 64px;
--space-20: 80px;
--space-24: 96px;
--space-30: 120px;
--space-40: 160px;
```

Spacing must communicate hierarchy:

- Closely related content uses tight spacing
- Separate content groups use medium spacing
- Major sections use generous spacing
- Premium layouts should breathe
- Mobile spacing must remain generous without wasting screen space

Avoid using the same padding value on every component.

---

## 9. Shape Language

The interface should combine clean digital geometry with a small amount of organic character.

Use:

- Rounded rectangular surfaces
- Irregular promotional shapes
- Curved image masks
- Soft organic dividers
- Occasional angled graphic elements
- Hand-drawn decorative marks
- Circular stamps or seals
- Bold editorial labels

Do not make every element pill-shaped.

### Radius Tokens

```css
--radius-xs: 6px;
--radius-sm: 10px;
--radius-md: 16px;
--radius-lg: 24px;
--radius-xl: 32px;
--radius-2xl: 40px;
--radius-pill: 999px;
```

Recommended usage:

- Small controls: 8–12px
- Inputs and buttons: 12–16px
- Standard surfaces: 16–24px
- Large image surfaces: 24–40px
- Tags and compact labels: pill radius only when appropriate

---

## 10. Surface and Elevation System

Surfaces should feel tactile, warm, and premium.

Use:

- Warm neutral backgrounds
- Thin tonal borders
- Soft layered shadows
- Subtle texture
- Controlled surface contrast
- Clear elevation hierarchy

### Border Tokens

```css
--border-subtle: 1px solid rgba(24, 22, 21, 0.08);
--border-default: 1px solid #DED4CC;
--border-strong: 1px solid rgba(24, 22, 21, 0.18);
```

### Shadow Tokens

```css
--shadow-xs: 0 2px 8px rgba(32, 24, 16, 0.05);
--shadow-sm: 0 8px 24px rgba(32, 24, 16, 0.07);
--shadow-md: 0 16px 50px rgba(32, 24, 16, 0.09);
--shadow-lg: 0 28px 80px rgba(32, 24, 16, 0.12);
```

Avoid:

- Harsh black shadows
- Excessive elevation
- Glowing effects
- Heavy glassmorphism
- Thick gray borders
- Shadows on every component

Use elevation only when it communicates visual hierarchy.

---

## 11. Imagery Art Direction

Food photography must be one of the strongest elements in the design.

Use photography that feels:

- Editorial
- Authentic
- Richly textured
- Warmly lit
- High resolution
- Naturally appetizing
- Cinematic but believable
- Consistent in color grading

Prefer:

- Close-up food textures
- Natural ingredient detail
- Warm shadows
- Rich reds, browns, creams, and golden tones
- Elegant plating
- Dynamic cropping
- Overhead and three-quarter camera angles
- Realistic portions
- Subtle lifestyle context

Avoid:

- Low-quality stock imagery
- Cool blue lighting
- Overexposure
- Artificial saturation
- Inconsistent photography styles
- Fake-looking food
- Excessive filters
- Cartoon imagery as the main visual style

### Image Treatments

Use:

- Warm color grading
- Controlled contrast
- Slight film grain
- Subtle vignette
- Soft natural shadows
- Editorial cropping
- Rounded or organic masks
- Selective red graphic overlays

Images must remain the focus. Decorative styling should support them rather than compete with them.

---

## 12. Illustration and Pattern System

Use subtle illustrations inspired by the uploaded menu.

Possible motifs:

- Abstract noodle lines
- Organic contour patterns
- Chili peppers
- Dumplings
- Chopsticks
- Sauce bottles
- Steam lines
- Ingredient silhouettes
- Japanese-inspired stamps
- Hand-drawn arrows
- Expressive bursts
- Minimal food icons

### Pattern Rules

- Background opacity: 4–8%
- Decorative illustration opacity: 10–18%
- Large watermark opacity: 3–6%
- Use warm gray, charcoal, or muted red
- Never reduce text readability
- Avoid using patterns in every section
- Keep illustration stroke weight consistent

The decorative system should feel custom, expressive, and controlled.

---

## 13. Iconography

Use a consistent custom-feeling icon system.

Recommended icon direction:

- Rounded line endings
- Slightly organic geometry
- Minimal internal detail
- 1.5–2px stroke
- Strong optical alignment
- Consistent visual weight

Primary icon sizes:

```css
--icon-sm: 16px;
--icon-md: 20px;
--icon-lg: 24px;
--icon-xl: 32px;
```

Do not mix unrelated icon libraries.

Do not randomly mix filled, outlined, multicolor, and 3D icons.

Filled icons may be used only for selected or highly emphasized states.

---

## 14. Buttons

Buttons must feel tactile, confident, and premium.

### Primary Button

```css
background: #B62329;
color: #FFFFFF;
min-height: 52px;
padding-inline: 24px;
border-radius: 14px;
font-weight: 600;
```

States:

- Hover: `#A11E24`
- Active: `#86181E`
- Focus ring: `0 0 0 4px rgba(182, 35, 41, 0.24)`
- Disabled: reduced contrast without losing readability

### Dark Button

```css
background: #181615;
color: #FFFFFF;
```

Hover:

```css
background: #2A2522;
```

### Light Button

```css
background: #FFF9F5;
color: #181615;
border: 1px solid #DED4CC;
```

### Button Rules

- Minimum touch target: 44×44px
- Preferred height: 48–56px
- Mobile primary buttons: 52–60px
- Include clear hover, active, focus, and disabled states
- Use icons only when they improve understanding
- Keep label and icon spacing consistent
- Avoid excessive pill-shaped buttons
- Avoid gradient buttons
- Avoid exaggerated shadows
- Avoid unnecessary glow effects

---

## 15. Form Controls

Form styling must feel calm, spacious, modern, and easy to use.

Recommended input styling:

```css
min-height: 54px;
padding-inline: 16px;
background: #FFF9F5;
border: 1px solid #DED4CC;
border-radius: 14px;
color: #181615;
```

Use:

- Persistent labels
- Clear placeholder contrast
- Visible focus states
- Calm validation styling
- Well-aligned icons
- Accessible helper text
- Comfortable mobile spacing

Avoid:

- Tiny form controls
- Invisible labels
- Extremely thin borders
- Aggressive red error states
- Cluttered fields
- Floating labels that harm readability

---

## 16. Navigation Styling

Navigation must feel elegant, lightweight, and intentionally composed.

Use:

- Strong spacing
- Clear hierarchy
- Refined logo placement
- Subtle active indicators
- Premium hover transitions
- Minimal visual noise
- Balanced desktop alignment
- Mobile-specific navigation composition

Desktop navigation may use:

- Warm cream surface
- Transparent background over imagery
- Subtle blur when necessary for readability
- Fine bottom border
- Controlled elevation after scrolling

Do not treat mobile navigation as a compressed desktop layout.

Mobile navigation must have:

- Large touch targets
- Clear spacing
- Strong contrast
- Simple visual hierarchy
- Safe-area support
- Smooth opening and closing motion

---

## 17. Card Design

Cards must not look like default template components.

Use several carefully controlled card treatments rather than one repeated pattern.

Possible treatments:

- Image-dominant editorial card
- Dark high-contrast card
- Cream bordered card
- Red promotional card
- Minimal text-only surface
- Overlapping image-and-content composition

Card rules:

- Strong image hierarchy
- Comfortable internal padding
- Limited metadata
- Clear typographic order
- Refined hover states
- Consistent image ratios
- Controlled corner radii
- No excessive badges
- No unnecessary borders around every card

Avoid placing everything inside a card.

---

## 18. Responsive Design

The experience must be intentionally designed for each breakpoint.

Do not simply scale down the desktop layout.

### Breakpoints

```css
--breakpoint-sm: 360px;
--breakpoint-md: 480px;
--breakpoint-lg: 768px;
--breakpoint-xl: 1024px;
--breakpoint-2xl: 1280px;
--breakpoint-3xl: 1600px;
```

### Mobile Requirements

On mobile:

- Recompose complex layouts vertically
- Preserve strong visual hierarchy
- Use large readable type
- Maintain generous touch targets
- Reduce nonessential decoration
- Use edge-to-edge imagery selectively
- Keep important controls reachable
- Respect device safe areas
- Avoid tiny horizontal card collections
- Avoid excessive nested containers
- Avoid horizontal page scrolling
- Do not reduce body text below readable sizes

### Tablet Requirements

On tablet:

- Avoid stretched mobile layouts
- Avoid compressed desktop layouts
- Use tablet-specific grid behavior
- Balance imagery and typography
- Preserve editorial composition
- Maintain comfortable margins

### Large Desktop Requirements

On large displays:

- Prevent content from becoming excessively wide
- Increase whitespace rather than stretching text
- Scale imagery thoughtfully
- Preserve maximum readable line lengths
- Keep compositions visually anchored

Test at minimum:

- 360px
- 390px
- 430px
- 768px
- 1024px
- 1280px
- 1440px
- 1920px

---

## 19. Motion System

Motion should feel smooth, premium, and restrained.

Use animation to improve hierarchy and tactile feedback, not to show off.

### Timing Tokens

```css
--duration-fast: 140ms;
--duration-normal: 240ms;
--duration-slow: 420ms;
--duration-reveal: 650ms;

--ease-standard: cubic-bezier(0.22, 1, 0.36, 1);
--ease-expressive: cubic-bezier(0.16, 1, 0.3, 1);
```

### Recommended Motion

- Gentle fade and rise
- Soft image reveal
- Subtle button press
- Underline expansion
- Controlled card elevation
- 1.02–1.04 image scaling on hover
- Staggered content entrances
- Smooth navigation transitions
- Refined mobile drawer animation
- Subtle decorative parallax

Avoid:

- Excessive bounce
- Spinning
- Constant floating
- Flashing
- Large zoom effects
- Slow interactions
- Overanimated text
- Animation on every element

Respect `prefers-reduced-motion`.

---

## 20. Microinteraction Quality

Every interactive element must have clear states:

- Default
- Hover
- Focus
- Active
- Selected
- Disabled
- Loading
- Error
- Success

State changes should be visible but not dramatic.

Use:

- Small position shifts
- Border-color transitions
- Background transitions
- Icon movement
- Subtle scale feedback
- Controlled elevation changes

Never rely on color alone to communicate state.

---

## 21. Accessibility

The design must remain premium while meeting accessibility expectations.

Requirements:

- WCAG-friendly color contrast
- Visible keyboard focus indicators
- Minimum 44×44px touch targets
- Readable body typography
- Clear heading hierarchy
- Semantic document structure
- Reduced-motion support
- Proper label association
- Distinguishable interaction states
- No essential information conveyed through color alone
- Comfortable line lengths
- Support for browser zoom
- Support for text enlargement
- Logical keyboard navigation
- Decorative imagery hidden from assistive technology when appropriate

Do not remove focus outlines without replacing them with an accessible alternative.

---

## 22. Design Tokens

Create centralized reusable tokens for:

- Brand colors
- Neutral colors
- Semantic colors
- Typography
- Font sizes
- Font weights
- Line heights
- Letter spacing
- Spacing
- Container widths
- Grid gutters
- Border widths
- Border radii
- Shadows
- Opacity
- Icon sizing
- Motion duration
- Easing curves
- Breakpoints
- Z-index layers

Example z-index system:

```css
--z-base: 0;
--z-raised: 10;
--z-sticky: 100;
--z-overlay: 500;
--z-drawer: 700;
--z-modal: 900;
--z-toast: 1000;
```

Avoid arbitrary values when a token exists.

---

## 23. Premium Visual Details

Introduce small, carefully controlled details that make the interface feel custom-built:

- Fine editorial dividers
- Hand-drawn red marks
- Circular recommendation stamps
- Minimal Japanese-inspired symbols
- Organic image masks
- Subtle grain
- Background contour lines
- Decorative typography
- Small icon illustrations
- Irregular section edges
- Controlled overlapping elements
- Bold red label blocks
- Oversized display typography
- Refined hover reveals
- Carefully placed accent marks

Use these details sparingly.

Every decorative element must support the brand identity or composition.

---

## 24. Visual Restraint

Do not use:

- Generic startup blue
- Purple gradients
- Neon colors
- Excessive orange
- Cold gray backgrounds
- Heavy glassmorphism
- Glossy gradients
- Excessive blur
- Strong black shadows
- Repetitive card grids
- Excessive pills
- Excessive badges
- Random 3D illustrations
- Emoji as interface icons
- Inconsistent border radii
- Multiple competing red shades
- Generic template sections
- Overcrowded compositions
- Decorative elements that reduce usability

Do not make every element rounded, floating, outlined, or elevated.

---

## 25. Quality-Control Checklist

Before completing the design, review every screen and component.

Confirm that:

- The interface has a distinctive identity
- The uploaded menu’s red direction is reflected
- The result feels premium rather than generic
- The cream, red, and charcoal balance is consistent
- Typography feels editorial and intentional
- Mobile layouts are independently composed
- Touch targets are comfortable
- No content overflows
- Spacing follows a clear rhythm
- Decorative patterns remain subtle
- Food imagery looks premium and consistent
- Buttons have complete interaction states
- Form fields have accessible focus states
- Motion is restrained
- Contrast is accessible
- Components use shared tokens
- Cards do not all look identical
- Pure white is not overused
- Gradients and glass effects are not overused
- The design looks polished at 360px and 1920px
- Nothing resembles an unfinished template

Continue refining any area that feels ordinary, overly generated, unbalanced, or visually cheap.

---

## 26. Final Design Standard

The final interface must look:

- Bespoke
- Expensive
- Appetizing
- Visually memorable
- Responsive
- Production-ready
- Art-directed
- Cohesive
- Accessible
- Portfolio-worthy
- Suitable for a premium international food brand

The final result should feel like a combination of a premium restaurant identity, contemporary Japanese food packaging, editorial food photography, and a sophisticated modern digital product.

Do not deliver a generic food delivery template.

Do not prioritize speed over visual quality.

Every detail, from spacing and typography to hover states and mobile composition, must feel deliberately designed.
