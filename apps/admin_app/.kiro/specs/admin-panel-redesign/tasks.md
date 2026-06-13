# Implementation Plan: Admin Panel Redesign

## Overview

This plan implements a comprehensive UI/UX redesign of the Wasabi Admin Panel. The approach is bottom-up: first establish the design token system and theme infrastructure, then build the reusable component library on top of tokens, then construct the layout system, and finally apply everything to each feature screen. Testing tasks are interleaved close to the code they validate.

## Tasks

- [x] 1. Design Token System and Theme Infrastructure
  - [x] 1.1 Create design token classes (ColorTokens, TypographyTokens, SpacingTokens, ElevationTokens, RadiusTokens)
    - Create `lib/core/theme/tokens/color_tokens.dart` with light and dark `ColorTokens` instances
    - Create `lib/core/theme/tokens/typography_tokens.dart` with named sizes, weights, font family, and `style()` builder
    - Create `lib/core/theme/tokens/spacing_tokens.dart` with 4px-based named constants
    - Create `lib/core/theme/tokens/elevation_tokens.dart` with BoxShadow configurations (alpha < 0.08)
    - Create `lib/core/theme/tokens/radius_tokens.dart` with named radii and BorderRadius getters
    - Create `lib/core/theme/tokens/app_tokens.dart` barrel class composing all token classes
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_

  - [x] 1.2 Create AppThemeExtension and ThemeData definitions
    - Create `lib/core/theme/app_theme_extension.dart` implementing `ThemeExtension<AppThemeExtension>` with `lerp()` and `copyWith()`
    - Create `lib/core/theme/app_theme.dart` with `lightTheme` and `darkTheme` ThemeData instances registering the extension
    - Add a convenience extension on `BuildContext` for accessing tokens (e.g., `context.tokens`)
    - _Requirements: 1.1, 18.1_

  - [x] 1.3 Create ThemeMode Riverpod provider with persistence
    - Create `lib/core/theme/theme_mode_provider.dart` using Riverpod to manage ThemeMode state
    - Load stored preference from SharedPreferences on init, default to light if absent
    - Implement `toggle()` method that switches mode and persists to SharedPreferences
    - _Requirements: 18.2, 18.3, 18.4, 18.6_

  - [x] 1.4 Write property tests for design tokens (Properties 1, 2, 12)
    - **Property 1: Spacing tokens are multiples of the base unit** — verify all SpacingTokens values are positive multiples of 4
    - **Property 2: Elevation shadow alpha constraint** — verify all ElevationTokens BoxShadow color alpha < 0.08
    - **Property 12: Responsive breakpoint resolution** — verify Breakpoints.fromWidth returns correct LayoutMode for any positive width
    - Create `test/core/theme/tokens_property_test.dart`
    - Create `test/core/theme/breakpoints_property_test.dart`
    - **Validates: Requirements 1.3, 1.4, 16.1**

- [x] 2. Checkpoint - Ensure token tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 3. Component Library — Buttons and Status Badges
  - [x] 3.1 Implement WButton component
    - Create `lib/core/widgets/w_button.dart` with `WButtonVariant` (primary, secondary, ghost, destructive) and `WButtonSize` (sm, md, lg) enums
    - Implement disabled state (opacity 0.5, ignores taps), loading state (16px spinner, maintains dimensions), and optional leading icon with 8px gap
    - Consume design tokens for all colors, radii, typography, and spacing
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_

  - [x] 3.2 Write property test for WButton size specifications (Property 3)
    - **Property 3: Button size specification consistency** — verify each WButtonSize maps to correct height/padding/text/icon dimensions
    - Create `test/core/widgets/w_button_property_test.dart`
    - **Validates: Requirements 2.4**

  - [x] 3.3 Implement WStatusBadge component with status mappings
    - Create `lib/core/widgets/w_status_badge.dart` with `StatusBadgeVariant` enum and rendering logic (tinted bg at 10% alpha, semantic text color, uppercase label, truncation at 20 chars)
    - Create `lib/core/widgets/status_mappings.dart` with `OrderStatusMapping.fromStatus()` and `RiderStatusMapping.fromStatus()` returning neutral for unknown strings
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6_

  - [x] 3.4 Write property tests for WStatusBadge (Properties 6, 7, 8)
    - **Property 6: StatusBadge variant color mapping consistency** — verify background = semantic color at 10% alpha, text = full semantic color
    - **Property 7: StatusBadge label formatting** — verify uppercase transform and 20-char truncation with ellipsis
    - **Property 8: Status string to variant mapping with fallback** — verify known statuses map correctly and unknown strings return neutral
    - Create `test/core/widgets/w_status_badge_property_test.dart`
    - **Validates: Requirements 4.2, 4.3, 4.4, 4.5, 4.6**

- [x] 4. Component Library — Data Table
  - [x] 4.1 Implement WDataTable component
    - Create `lib/core/widgets/w_data_table.dart` with generic `WDataTable<T>` and `WTableColumn<T>` classes
    - Implement alternating row colors (gray50/white), 64px row height, hover highlight (gray100), column headers (w600, sm, uppercase, secondary color)
    - Implement loading state (5 shimmer rows), error state (WErrorState with retry), empty state (WEmptyState)
    - Implement sortable columns with direction toggle and sort indicator icon
    - Implement pagination controls: page size selector (10, 25, 50), row range indicator, prev/next buttons with correct disabled states
    - Minimum table width 1000px with horizontal scroll on narrow viewports
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8, 3.9, 16.6_

  - [x] 4.2 Write property tests for WDataTable logic (Properties 4, 5)
    - **Property 4: Sort column toggle is an involution** — verify tapping a sortable column header twice returns sort to original direction
    - **Property 5: Pagination navigation button state correctness** — verify prev disabled iff page==1, next disabled iff page==totalPages
    - Create `test/core/widgets/w_data_table_property_test.dart`
    - **Validates: Requirements 3.7, 3.9**

- [x] 5. Component Library — Dialog, Form Inputs, and State Widgets
  - [x] 5.1 Implement WDialog component
    - Create `lib/core/widgets/w_dialog.dart` with maxWidth 560px, radius xl, padding 24px
    - Implement header (title lg w600, optional subtitle, close button), scrollable content, footer (right-aligned actions, 12px gap)
    - Implement fade-in 200ms / fade-out 150ms animations, backdrop black 40% alpha, backdrop dismiss
    - _Requirements: 13.1, 13.2, 13.3, 13.4, 13.5, 13.6, 13.7_

  - [x] 5.2 Implement form input components (WTextInput, WSelectInput, WSearchInput)
    - Create `lib/core/widgets/w_text_input.dart` — height 36px, radius md, 1px border, 2px focus border (primary), hPadding 12px, label (sm, w500, 4px bottom), error text (error color, xs, max 2 lines, 4px top), disabled state (opacity 0.5, gray50 fill)
    - Create `lib/core/widgets/w_select_input.dart` — matching TextInput styling, max 6 visible dropdown items
    - Create `lib/core/widgets/w_search_input.dart` — leading search icon 20px, 300ms debounce on onChange
    - _Requirements: 14.1, 14.2, 14.3, 14.4, 14.5, 14.6_

  - [x] 5.3 Implement state widgets (WSkeletonLoader, WErrorState, WEmptyState)
    - Create `lib/core/widgets/w_skeleton_loader.dart` with variants (table, kpiCards, chart, generic) and 1.5s shimmer cycle using `shimmer` package
    - Create `lib/core/widgets/w_error_state.dart` — error icon 24px, title "Something went wrong", message (max 150 chars, ellipsis), retry button (secondary variant)
    - Create `lib/core/widgets/w_empty_state.dart` — icon 48px, title, optional subtitle, optional action button
    - _Requirements: 15.1, 15.2, 15.3, 15.4, 15.5, 15.6_

  - [x] 5.4 Write widget tests for dialog and form inputs
    - Test WDialog: open/close animations, backdrop dismiss, scrollable content, header/footer rendering
    - Test WTextInput: focus state, error display, disabled state, label rendering
    - Test WSelectInput: dropdown opens with max 6 items, selection callback
    - Test WSearchInput: debounce behavior, icon rendering
    - Create `test/core/widgets/w_dialog_test.dart`, `test/core/widgets/w_form_inputs_test.dart`
    - _Requirements: 13.1–13.7, 14.1–14.6_

- [x] 6. Checkpoint - Ensure all component tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 7. Layout System — AppShell, Sidebar, Header
  - [x] 7.1 Implement responsive Breakpoints utility and AppShell layout
    - Create `lib/core/widgets/layouts/breakpoints.dart` with `Breakpoints` class and `LayoutMode` enum
    - Create `lib/core/widgets/layouts/app_shell.dart` as a ConsumerWidget using LayoutBuilder
    - Implement expanded (260px sidebar + 32px content padding), medium (64px rail + 24px padding), compact (no sidebar, hamburger + drawer overlay, 16px padding)
    - Remove the duplicate sidebar implementation and consolidate into the single AppShell pattern
    - _Requirements: 16.1, 16.2, 16.3, 16.4, 16.7, 21.4_

  - [x] 7.2 Implement SidebarNavigation component
    - Create `lib/core/widgets/layouts/sidebar_navigation.dart` as a ConsumerWidget
    - Implement navigation sections (Main, Management, Marketing, People, Assets) with section labels (uppercase, xs, w600, secondary color, 16px bottom margin)
    - Implement active state (3px left border primary, 8% primary bg, primary icon+text w600), hover state (gray100, 150ms transition)
    - Implement collapsed rail mode (64px, icon-only with tooltips)
    - Implement user profile section at bottom (36px avatar with initials, name, role, logout button)
    - Use SVG icons at 20px consistent size
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7, 5.8_

  - [x] 7.3 Implement HeaderBar component
    - Create `lib/core/widgets/layouts/header_bar.dart` as a ConsumerWidget
    - Implement fixed height 56px, bottom border 1px
    - Implement search input (36px, radius md, 300ms debounce, max 8 results dropdown)
    - Implement notification bell (20px icon, badge hidden at 0, numeric 1-99, "99+" above 99)
    - Implement user avatar (32px circle, initials fallback) and name (text sm)
    - Implement breadcrumb trail (max 4 levels, clickable ancestors, "/" divider)
    - Implement theme toggle (sun/moon icon) in profile section
    - Implement hamburger button on compact viewport using scaffoldKey
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 6.7, 6.8, 18.2_

  - [x] 7.4 Write property tests for navigation and header logic (Properties 9, 10, 11)
    - **Property 9: Navigation item active state determination** — verify active iff path == route or (route != '/' and path.startsWith(route))
    - **Property 10: Notification badge display logic** — verify hidden at 0, numeric 1-99, "99+" above 99
    - **Property 11: Breadcrumb depth constraint** — verify max 4 levels, last min(N,4) segments shown, all but final clickable
    - Create `test/core/navigation/sidebar_property_test.dart`, `test/core/navigation/header_property_test.dart`
    - **Validates: Requirements 5.3, 6.4, 6.7**

  - [x] 7.5 Write widget tests for AppShell, Sidebar, and Header
    - Test AppShell: renders correct layout at each breakpoint (expanded, medium, compact)
    - Test SidebarNavigation: section grouping, active item styling, rail mode, logout action
    - Test HeaderBar: search debounce, notification badge states, breadcrumb rendering, theme toggle
    - Create `test/core/navigation/app_shell_test.dart`, `test/core/navigation/sidebar_test.dart`, `test/core/navigation/header_test.dart`
    - _Requirements: 5.1–5.8, 6.1–6.8, 16.1–16.7_

- [x] 8. Checkpoint - Ensure layout and navigation tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 9. Route Transitions and GoRouter Integration
  - [x] 9.1 Implement fade transition helper and update GoRouter configuration
    - Create `lib/core/router/route_transitions.dart` with `fadeTransition()` helper returning `CustomTransitionPage`
    - Update GoRouter page builders: 200ms fade for all ShellRoute children, 300ms fade for login route
    - Ensure browser back/forward applies the same fade transition
    - Remove any existing slide/scale/rotation/bounce transitions
    - _Requirements: 17.1, 17.2, 17.3, 17.4_

- [x] 10. Login Screen Redesign
  - [x] 10.1 Redesign login screen with glassmorphic card and token-based styling
    - Update `lib/features/auth/presentation/screens/login_screen.dart`
    - Implement dark gradient background, centered glassmorphic card (backdrop-blur, semi-transparent fill, 1px border at 10% white opacity), brand mark above form title
    - Remove any decorative background shapes (circles, blobs)
    - Replace all `withOpacity` calls with `Color.withValues(alpha: value)`
    - Implement email validation (non-empty, contains @ followed by .), password validation (non-empty)
    - Implement inline error display below fields (error color, 14px), clear on field modification
    - Implement loading state on submit button (spinner replaces label, button disabled)
    - Use 300ms fade transition for login route
    - _Requirements: 19.1, 19.2, 19.3, 19.4, 19.5, 19.6, 19.7_

  - [x] 10.2 Write property test for email validation (Property 13)
    - **Property 13: Email validation correctness** — verify accepts strings with @ followed by . (with chars between/after), rejects empty strings and strings without valid pattern
    - Create `test/features/auth/login_validation_property_test.dart`
    - **Validates: Requirements 19.6**

  - [x] 10.3 Write widget tests for login screen
    - Test form validation prevents submission with invalid inputs
    - Test inline error display and clearing behavior
    - Test loading state on submit button
    - Create `test/features/auth/login_screen_test.dart`
    - _Requirements: 19.4, 19.5, 19.6, 19.7_

- [x] 11. Dashboard Screen Redesign
  - [x] 11.1 Redesign dashboard screen with KPI cards, chart, and activity feed
    - Update `lib/features/dashboard/presentation/screens/dashboard_screen.dart`
    - Implement 4-column KPI card grid (responsive: 4 expanded, 2 medium, 1 compact) with muted label (sm, secondary), value (xl, w700), small icon (16px, secondary, no background shape), 16px gaps
    - Implement revenue line chart card (min height 300px, title md w600, axis labels xs secondary, primary-colored 2px line)
    - Implement recent activity feed (10 items, 8px status dot colored by type, description sm, relative timestamp xs secondary)
    - Use 24px gaps between major sections
    - Implement skeleton loading state (KPI + chart skeleton variants) and error state with retry
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6, 7.7, 16.5_

- [x] 12. Orders Management Screen Redesign
  - [x] 12.1 Redesign orders screen with DataTable, filters, and status badges
    - Update `lib/features/orders/presentation/screens/orders_screen.dart`
    - Implement WDataTable with columns: Order ID, Customer, Items, Total, Status (WStatusBadge), Actions
    - Implement filter chips (All, Preparing, On the Way, Delivered, Cancelled) — All active by default, filled primary+white text when active, outlined+secondary when inactive
    - Implement row-level actions (View Details, Update Status) as icon buttons with tooltips
    - Implement View Details dialog showing full order info (customer, items, timeline)
    - Implement Update Status dialog with available next status options and confirmation
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6, 8.7, 8.8_

- [x] 13. Menu Management Screen Redesign
  - [x] 13.1 Redesign menu screen with DataTable, item dialog, and availability toggle
    - Update `lib/features/menu/presentation/screens/menu_screen.dart`
    - Implement WDataTable with columns: Item (40x40 rounded thumbnail + name), Category, Price, Availability (Switch, success color active), Actions
    - Implement Add/Edit item dialog with fields: name, description, category dropdown, price, compare-at price, tags, image, availability toggle, featured toggle, add-on selection
    - Implement delete confirmation dialog (destructive confirm, secondary cancel)
    - Implement form validation (name, category, price required) with inline errors
    - Implement availability toggle revert on API failure
    - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5, 9.6, 9.7, 9.8_

- [x] 14. Customers Screen Redesign
  - [x] 14.1 Redesign customers screen with DataTable, search, and profile dialog
    - Update `lib/features/customers/presentation/screens/customers_screen.dart`
    - Implement WDataTable with columns: Customer (32px avatar + name), Contact, Total Orders, Total Spent, Join Date, Actions
    - Implement search input with 300ms debounce filtering by name/email
    - Implement customer avatars (32px circle, initials fallback, primary 10% alpha bg)
    - Implement View Profile dialog (contact info + recent 10 orders with date, status, total)
    - Implement empty state when search yields no results, restore full list on clear
    - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5, 10.6_

- [x] 15. Riders Screen Redesign
  - [x] 15.1 Redesign riders screen with DataTable, tabs, and approval workflow
    - Update `lib/features/riders/presentation/screens/riders_screen.dart`
    - Implement WDataTable with columns: Rider (32px avatar + name), Contact, Vehicle Type, Status (WStatusBadge), Actions
    - Implement tab navigation (Active Riders, Pending Applications) with primary active indicator
    - Implement Approve (success variant) and Reject (destructive variant) action buttons for pending tab
    - Implement reject confirmation dialog (destructive variant)
    - Implement error handling: preserve current status on approve/reject failure
    - Implement list refresh and tab movement on successful approve/reject
    - _Requirements: 11.1, 11.2, 11.3, 11.4, 11.5, 11.6, 11.7_

- [x] 16. Banners, Coupons, and Media Screens Redesign
  - [x] 16.1 Redesign banners screen
    - Update `lib/features/banners/presentation/screens/banners_screen.dart`
    - Implement WDataTable with columns: Thumbnail (48x32 rounded), Title, Status (StatusBadge), Schedule, Sort Order, Actions (Edit, Delete with tooltips)
    - Implement page header with breadcrumb, title, and "New Banner" primary action button
    - Implement create/edit dialog using WDialog, delete confirmation with destructive button
    - Implement loading/error/empty states
    - _Requirements: 12.1, 12.4, 12.5, 12.6, 12.7_

  - [x] 16.2 Redesign coupons screen
    - Update `lib/features/coupons/presentation/screens/coupons_screen.dart`
    - Implement WDataTable with columns: Code, Discount (value+type), Min Order Amount, Valid Period, Status (StatusBadge active/expired), Actions (Edit, Delete with tooltips)
    - Implement page header with breadcrumb, title, and "New Coupon" primary action button
    - Implement create/edit dialog using WDialog, delete confirmation with destructive button
    - Implement loading/error/empty states
    - _Requirements: 12.2, 12.4, 12.5, 12.6, 12.7_

  - [x] 16.3 Redesign media screen
    - Update `lib/features/media/presentation/screens/media_screen.dart`
    - Implement card grid layout with 160x160 thumbnails, radius lg, hover overlay with Delete and Copy URL actions
    - Implement page header with breadcrumb, title, and "Upload Image" primary action button
    - Implement delete confirmation dialog with destructive button
    - Implement loading/error/empty states
    - _Requirements: 12.3, 12.4, 12.5, 12.6, 12.7_

- [x] 17. Checkpoint - Ensure all screen implementations are consistent
  - Ensure all tests pass, ask the user if questions arise.

- [x] 18. Deprecation Cleanup and Code Quality
  - [x] 18.1 Replace all deprecated withOpacity calls and fix analyzer warnings
    - Search and replace all `Color.withOpacity()` → `Color.withValues(alpha: value)` across all Dart files
    - Remove all unused imports identified by dart analyzer
    - Fix all info-level analyzer warnings (unnecessary underscores, missing blocks, unnecessary type annotations)
    - Verify `dart analyze` produces zero warnings at info level or above
    - _Requirements: 1.6, 21.1, 21.2, 21.3, 21.5_

- [x] 19. Accessibility Compliance
  - [x] 19.1 Add semantic labels, keyboard navigation, and focus indicators
    - Add Semantics/tooltip to all icon-only buttons and interactive elements
    - Ensure Tab/Shift+Tab logical order (sidebar → header → content), Enter/Space activation, Escape to close dialogs, Arrow keys in composite widgets
    - Ensure minimum 44x44px touch targets on all interactive elements
    - Add 2px primary-colored focus outline with 2px offset on all focusable elements
    - Add Semantics for data tables (row/column headers), navigation landmark, form controls (labels, validation states), button states
    - Implement focus trap in dialogs (move focus to first element, constrain Tab, return focus on close)
    - Add live-region semantics for dynamic content changes (filtering, sorting, pagination, validation errors)
    - Announce status messages to screen readers without requiring navigation
    - _Requirements: 20.1, 20.2, 20.3, 20.4, 20.5, 20.6, 20.7, 20.8_

- [x] 20. Final Checkpoint - Full verification
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests validate universal correctness properties from the design document
- Widget tests validate specific component rendering and interaction behavior
- The redesign is purely presentational — no business logic, API, or state management changes
- All components consume design tokens; no hardcoded values in screen-level code
- The `shimmer` package is used for skeleton loading animations
- Existing `data_table_2` package is retained but wrapped in the custom WDataTable component

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1"] },
    { "id": 1, "tasks": ["1.2", "1.3"] },
    { "id": 2, "tasks": ["1.4", "3.1", "3.3"] },
    { "id": 3, "tasks": ["3.2", "3.4", "4.1", "5.1", "5.2", "5.3"] },
    { "id": 4, "tasks": ["4.2", "5.4", "7.1"] },
    { "id": 5, "tasks": ["7.2", "7.3"] },
    { "id": 6, "tasks": ["7.4", "7.5", "9.1"] },
    { "id": 7, "tasks": ["10.1", "11.1"] },
    { "id": 8, "tasks": ["10.2", "10.3", "12.1", "13.1", "14.1", "15.1"] },
    { "id": 9, "tasks": ["16.1", "16.2", "16.3"] },
    { "id": 10, "tasks": ["18.1"] },
    { "id": 11, "tasks": ["19.1"] }
  ]
}
```
