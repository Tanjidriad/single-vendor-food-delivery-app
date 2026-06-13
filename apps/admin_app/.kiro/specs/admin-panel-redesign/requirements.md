# Requirements Document

## Introduction

This document defines the requirements for a comprehensive UI/UX redesign of the Wasabi Admin Panel — a Flutter-based food delivery management dashboard. The redesign establishes a professional, premium design system and applies it consistently across all screens. The scope is limited to the presentation layer; business logic, API integrations, state management (Riverpod), and routing (GoRouter) remain unchanged.

The target aesthetic is a dense, readable, production-ready admin dashboard with restrained color usage, compact typography, subtle shadows, and refined borders — comparable to premium CodeCanyon products.

## Glossary

- **Design_System**: The centralized collection of design tokens (colors, typography, spacing, elevation, radii) and reusable component specifications that govern the visual language of the Admin Panel.
- **Admin_Panel**: The Flutter web application ("Wasabi Admin Panel") used by restaurant administrators to manage orders, menu items, customers, riders, banners, coupons, and media.
- **Design_Token**: A named constant representing a single visual attribute (color, spacing value, font size, shadow, radius) used consistently throughout the application.
- **Component_Library**: The set of reusable Flutter widgets (buttons, cards, badges, inputs, tables, dialogs, navigation items) built on top of the Design_System.
- **Skeleton_Screen**: A placeholder UI showing the structural layout of content with animated shimmer effects while data loads.
- **Empty_State**: A composed UI shown when a data list or view contains zero items, including an illustration, descriptive text, and an optional action.
- **Error_State**: A composed UI shown when a data fetch or operation fails, including an icon, error description, and a retry action.
- **Responsive_Breakpoint**: A viewport width threshold at which the layout adapts its structure (sidebar collapse, column count, padding adjustments).
- **Status_Badge**: A small, colored label widget indicating the state of an entity (order status, rider approval, item availability).
- **KPI_Card**: A compact metric display widget showing a title, value, optional trend indicator, and icon.
- **Sidebar_Navigation**: The primary vertical navigation component providing access to all feature screens.
- **Header_Bar**: The top horizontal bar containing global search, notifications, and user profile controls.
- **Route_Transition**: An animated visual effect applied when navigating between screens.
- **Dark_Mode**: An alternative color scheme using dark backgrounds and light foreground elements for low-light environments.
- **Deprecated_API**: Flutter APIs marked for removal (e.g., `withOpacity`) that must be replaced with current equivalents (e.g., `withValues`).

## Requirements

### Requirement 1: Design Token System

**User Story:** As a developer, I want a centralized design token system, so that visual consistency is enforced across all screens without magic numbers.

#### Acceptance Criteria

1. THE Design_System SHALL define a color palette containing: a neutral gray scale (50–900), a single primary accent color, semantic colors (success, warning, error, info) each with base and light variants, and surface/background/border tokens.
2. THE Design_System SHALL define a typography scale with named sizes (xs: 11px, sm: 12px, base: 13px, md: 14px, lg: 16px, xl: 18px, 2xl: 20px, 3xl: 24px) and named font weights (regular: w400, medium: w500, semibold: w600, bold: w700) using Plus Jakarta Sans as the sole typeface.
3. THE Design_System SHALL define a spacing scale using a 4px base unit with named constants (xs: 4, sm: 8, md: 12, lg: 16, xl: 20, 2xl: 24, 3xl: 32, 4xl: 40, 5xl: 48).
4. THE Design_System SHALL define elevation tokens (none, sm, md, lg) as BoxShadow configurations using neutral colors with alpha values below 0.08.
5. THE Design_System SHALL define border radius tokens (none: 0, sm: 4, md: 6, lg: 8, xl: 12, 2xl: 16).
6. THE Design_System SHALL replace all deprecated `withOpacity` calls with `Color.withValues(alpha: value)` throughout the codebase.
7. THE Design_System SHALL eliminate all hardcoded numeric values for spacing, font sizes, and radii from screen-level code by referencing named token constants.

---

### Requirement 2: Button Component System

**User Story:** As a developer, I want a standardized button component with defined variants, so that button usage is consistent and predictable across all screens.

#### Acceptance Criteria

1. THE Component_Library SHALL provide button variants: primary (filled accent background, onPrimary text), secondary (1px border using border token, transparent background, primary text), ghost (transparent background, primary text, no border), and destructive (error-colored fill, onPrimary text), all using border radius md.
2. WHILE a button is in the disabled state, THE Component_Library SHALL render the button with reduced opacity (0.5) and ignore tap events.
3. WHILE a button is in the loading state, THE Component_Library SHALL display a spinner of 16px diameter in place of the label text while maintaining the button's original dimensions, and SHALL ignore tap events.
4. THE Component_Library SHALL provide button sizes: sm (height 32px, horizontal padding 12px, text sm), md (height 36px, horizontal padding 16px, text base), lg (height 40px, horizontal padding 20px, text md), with md as the default size.
5. THE Component_Library SHALL support an optional leading icon (sized 16px for sm, 18px for md, 20px for lg) with an 8px gap between the icon and label text for all button variants.

---

### Requirement 3: Data Table Component

**User Story:** As a developer, I want a polished, reusable data table component, so that all list views share consistent interaction patterns and visual treatment.

#### Acceptance Criteria

1. THE Component_Library SHALL provide a DataTable widget with alternating row backgrounds using gray50 and white surface colors, a data row height of 64px, and a minimum table width of 1000px.
2. WHEN a user hovers over a table row, THE Component_Library SHALL highlight the row with a gray100 background color.
3. THE Component_Library SHALL display column headers with font weight w600, text size sm, uppercase text, and secondary text color from the Design_System color tokens.
4. WHEN data is loading, THE Component_Library SHALL display a Skeleton_Screen with 5 animated shimmer placeholder rows matching the table column structure and row height.
5. WHEN the data set is empty, THE Component_Library SHALL display an Empty_State with an illustrative icon (48px), a title describing the empty condition, and an optional action button.
6. WHEN a data fetch fails, THE Component_Library SHALL display an Error_State with an error icon (24px, error color), an error message text, and a retry button that invokes the parent-provided data fetch callback.
7. WHEN a user taps a sortable column header, THE Component_Library SHALL toggle the sort direction (ascending/descending) for that column, display the active sort direction indicator icon in the column header, and invoke the parent-provided sort callback with the column index and direction.
8. THE Component_Library SHALL render pagination controls with a page size selector offering options of 10, 25, and 50 rows (default: 10), a current page indicator showing the displayed row range and total count, and previous/next navigation buttons.
9. IF the user is on the first page, THEN THE Component_Library SHALL disable the previous navigation button; IF the user is on the last page, THEN THE Component_Library SHALL disable the next navigation button.

---

### Requirement 4: Status Badge Component

**User Story:** As a developer, I want a unified status badge component, so that entity states are displayed consistently across orders, riders, and menu items.

#### Acceptance Criteria

1. THE Component_Library SHALL provide a StatusBadge widget accepting a label string (maximum 20 characters) and a semantic color variant (success, warning, error, info, neutral).
2. THE Component_Library SHALL render the StatusBadge with a tinted background (semantic color at 10% alpha), the semantic color as text color, font size xs, font weight w600, border radius sm, and horizontal padding of 8px with vertical padding of 4px.
3. THE Component_Library SHALL display the label text in uppercase and truncate with an ellipsis if the label exceeds the maximum character length.
4. THE Component_Library SHALL provide a predefined mapping from order status strings to semantic color variants: PENDING to warning, PREPARING to info, ON_THE_WAY to info, DELIVERED to success, and CANCELLED to error.
5. THE Component_Library SHALL provide a predefined mapping from rider approval status strings to semantic color variants: APPROVED to success, PENDING to warning, REJECTED to error, and SUSPENDED to error.
6. IF the StatusBadge receives a status string not present in the predefined mappings, THEN THE Component_Library SHALL render the badge using the neutral color variant.

---

### Requirement 5: Sidebar Navigation Redesign

**User Story:** As an administrator, I want a polished sidebar navigation with visual hierarchy and interaction feedback, so that I can navigate the panel efficiently.

#### Acceptance Criteria

1. THE Sidebar_Navigation SHALL display a brand header containing the application logo and name "Wasabi Admin" with font weight w700 and size lg, with a white background and a right border of 1px using the border token color.
2. THE Sidebar_Navigation SHALL group navigation items into labeled sections: "Main" (Dashboard), "Management" (Orders, Menu, Add-ons), "Marketing" (Banners, Coupons), "People" (Customers, Riders), and "Assets" (Media), where each section label is displayed in uppercase text with font size xs, font weight w600, secondary text color, and 16px bottom margin from the first item in the section.
3. WHILE a navigation item's route matches the current location path or is a prefix of it, THE Sidebar_Navigation SHALL display a left border accent (3px primary color), a tinted background (primary at 8% alpha), and primary-colored icon and text with font weight w600.
4. WHEN a user hovers over an inactive navigation item, THE Sidebar_Navigation SHALL display a subtle background tint (gray100) with a 150ms transition duration.
5. THE Sidebar_Navigation SHALL display a user profile section at the bottom containing a 36px circular avatar with initials fallback using a muted primary background, the user name in font weight w600, a role label in font size xs with secondary text color, and a logout icon button.
6. WHEN the logout button is pressed, THE Sidebar_Navigation SHALL invoke the authentication logout action and navigate the user to the login screen.
7. THE Sidebar_Navigation SHALL use a fixed width of 260px on viewports of 1200px or above.
8. THE Sidebar_Navigation SHALL use SVG icons with consistent 20px dimensions for all navigation items.

---

### Requirement 6: Header Bar Redesign

**User Story:** As an administrator, I want a functional header bar with search, notifications, and profile access, so that I can perform global actions from any screen.

#### Acceptance Criteria

1. THE Header_Bar SHALL display a search input field with a search icon, placeholder text "Search orders, menu items...", a border radius of md, and a height of 36px.
2. WHEN a user types in the search field, THE Header_Bar SHALL display filtered results in a dropdown overlay below the search field after a 300ms debounce period, showing a maximum of 8 matching items with their category label and name.
3. THE Header_Bar SHALL display a notification bell icon with a 20px icon size.
4. IF the unread notification count is greater than zero, THEN THE Header_Bar SHALL display a badge indicator on the notification bell showing the numeric count, capped at "99+" for counts exceeding 99.
5. THE Header_Bar SHALL display the current user avatar as a 32px circle (initials fallback using the primary color background) followed by the user name in text size sm.
6. THE Header_Bar SHALL have a fixed height of 56px with a bottom border of 1px using the border token color.
7. THE Header_Bar SHALL display a breadcrumb trail showing the current navigation path with clickable ancestor segments separated by a forward-slash divider, displaying a maximum depth of 4 levels.
8. IF the search field is empty or cleared, THEN THE Header_Bar SHALL hide the results dropdown and display only the placeholder text.

---

### Requirement 7: Dashboard Screen Redesign

**User Story:** As an administrator, I want a compact, data-dense dashboard, so that I can assess business health at a glance without visual clutter.

#### Acceptance Criteria

1. THE Admin_Panel SHALL display KPI cards in a 4-column grid with each KPI_Card showing: a muted label (text sm, secondary color), a value (text xl, font weight w700), and a small icon (16px, secondary color) without a background shape or tinted circle around the icon.
2. THE Admin_Panel SHALL NOT use tinted or filled background shapes around KPI icons, value text larger than the xl design token (18px), or gradient backgrounds on KPI cards.
3. THE Admin_Panel SHALL display a revenue line chart in a card container (minimum height 300px) with a compact title (text md, w600), axis labels (text xs, secondary color), and a single-color line using the primary accent with a line width of 2px.
4. THE Admin_Panel SHALL display a recent activity feed in a card container showing the 10 most recent items, with each item showing: a status dot (8px circle, colored by activity type: success color for completed events, primary color for new orders, error color for failures, warning color for alerts, info color for general updates), description text (text sm), and a relative timestamp in short format (text xs, secondary color, e.g. "2m ago", "1h ago", "3d ago").
5. THE Admin_Panel SHALL use consistent 16px gaps between KPI cards and 24px gaps between major sections (KPI row, chart row, activity feed row).
6. WHEN dashboard data is loading, THE Admin_Panel SHALL display skeleton placeholders matching the KPI card grid and chart layout structure instead of a plain loading spinner.
7. WHEN the dashboard data fetch fails, THE Admin_Panel SHALL display the standardized Error_State with a retry action instead of a raw error string.

---

### Requirement 8: Orders Management Screen Redesign

**User Story:** As an administrator, I want a functional orders table with working filters and clear status indicators, so that I can manage live orders efficiently.

#### Acceptance Criteria

1. THE Admin_Panel SHALL display orders in the standardized DataTable component with columns: Order ID, Customer, Items, Total, Status, and Actions.
2. THE Admin_Panel SHALL display filter chips (All, Preparing, On the Way, Delivered, Cancelled) with the "All" chip active by default on screen load.
3. WHEN a filter chip is tapped, THE Admin_Panel SHALL set that chip as active, deactivate all other chips, and display only orders matching the selected status; the "All" chip SHALL display orders of every status.
4. WHILE a filter chip is active, THE Admin_Panel SHALL render the chip with a filled primary background and white text; inactive chips SHALL use an outlined style with secondary text.
5. THE Admin_Panel SHALL display order status using the standardized StatusBadge component with the predefined order status color mapping.
6. THE Admin_Panel SHALL provide row-level actions (View Details, Update Status) accessible via icon buttons with tooltips.
7. WHEN the View Details action is triggered on an order row, THE Admin_Panel SHALL open a dialog or navigate to a detail view displaying the full order information including customer details, item list, and order timeline.
8. WHEN the Update Status action is triggered on an order row, THE Admin_Panel SHALL open a dialog presenting the available next status options, and upon confirmation SHALL update the order status and refresh the table to reflect the change.

---

### Requirement 9: Menu Management Screen Redesign

**User Story:** As an administrator, I want a polished menu management interface, so that I can browse, add, edit, and remove menu items with confidence.

#### Acceptance Criteria

1. THE Admin_Panel SHALL display menu items in the standardized paginated DataTable component with columns: Item (image + name), Category, Price, Availability, and Actions.
2. THE Admin_Panel SHALL display item images as 40x40px rounded thumbnails (radius sm) with a neutral placeholder icon when no image is available.
3. THE Admin_Panel SHALL display the availability toggle as a Switch widget using success color for the active thumb state, matching the height of a standard table row.
4. WHEN the Add New Item button is pressed, THE Admin_Panel SHALL open a dialog using the standardized dialog component with form fields for: item name, description, category (dropdown), price, compare-at price (optional), tags, product image, availability toggle, featured toggle, and add-on selection.
5. WHEN the Edit action is triggered on a row, THE Admin_Panel SHALL open the same item dialog pre-populated with the selected item's current values.
6. WHEN the Delete action is triggered, THE Admin_Panel SHALL display a confirmation dialog that identifies the item by name and uses the destructive button variant for the confirm action and a secondary button for cancel.
7. IF a required form field (name, category, price) is empty or invalid on submission, THEN THE Admin_Panel SHALL display an inline validation error below the respective field and prevent the form from submitting.
8. IF the availability toggle update fails, THEN THE Admin_Panel SHALL revert the toggle to its previous state and display an error message indicating the update could not be saved.

---

### Requirement 10: Customers Screen Redesign

**User Story:** As an administrator, I want a searchable customer list with profile access, so that I can find and review customer information quickly.

#### Acceptance Criteria

1. THE Admin_Panel SHALL display customers in the standardized DataTable component with columns: Customer (avatar + name), Contact, Total Orders, Total Spent, Join Date, and Actions.
2. WHEN the user types in the customer search input, THE Admin_Panel SHALL filter the displayed customer list by name or email after a 300ms debounce period.
3. THE Admin_Panel SHALL display customer avatars as 32px circles with initials fallback using the primary color at 10% alpha as the background.
4. WHEN the View Profile action is triggered, THE Admin_Panel SHALL display a customer detail dialog showing contact information (name, email, phone) and the most recent orders (up to 10 entries) with order date, status, and total.
5. IF the search input yields no matching customers, THEN THE Admin_Panel SHALL display the standardized Empty_State indicating no customers match the search query.
6. WHEN the search input is cleared, THE Admin_Panel SHALL restore the full unfiltered customer list.

---

### Requirement 11: Riders Screen Redesign

**User Story:** As an administrator, I want a clear rider management interface with approval workflows, so that I can review and manage rider applications efficiently.

#### Acceptance Criteria

1. THE Admin_Panel SHALL display riders in the standardized DataTable component with columns: Rider (32px circular avatar with initials fallback + name), Contact, Vehicle Type, Status, and Actions.
2. THE Admin_Panel SHALL provide tab navigation (Active Riders, Pending Applications) using a styled tab bar with primary-colored active indicator and secondary-colored inactive text.
3. WHEN viewing pending applications, THE Admin_Panel SHALL display Approve and Reject action buttons using success and destructive button variants respectively, alongside a View Profile action.
4. THE Admin_Panel SHALL display rider approval status using the standardized StatusBadge component with the predefined rider status color mapping.
5. WHEN the Reject action is triggered, THE Admin_Panel SHALL display a confirmation dialog using the destructive button variant before executing the rejection.
6. IF an approve or reject operation fails, THEN THE Admin_Panel SHALL display an error indication to the administrator and preserve the rider's current status unchanged.
7. WHEN an approve or reject operation succeeds, THE Admin_Panel SHALL refresh the riders list and move the affected rider to the appropriate tab (Active Riders for approved, removed from both for rejected).

---

### Requirement 12: Banners, Coupons, and Media Screens Redesign

**User Story:** As an administrator, I want consistent management interfaces for banners, coupons, and media, so that marketing and asset management feels cohesive with the rest of the panel.

#### Acceptance Criteria

1. THE Admin_Panel SHALL display banners in the standardized DataTable component with columns: Thumbnail (image preview, 48x32px rounded with radius sm), Title, Status (using StatusBadge), Schedule (start/end dates), Sort Order, and Actions (Edit, Delete icon buttons with tooltips).
2. THE Admin_Panel SHALL display coupons in the standardized DataTable component with columns: Code, Discount (value and type), Min Order Amount, Valid Period (start/end dates), Status (using StatusBadge showing active/expired), and Actions (Edit, Delete icon buttons with tooltips).
3. THE Admin_Panel SHALL display the Media management screen as a card grid layout with thumbnails rendered at a fixed 160x160px size, border radius lg, and a hover overlay containing Delete and Copy URL action buttons.
4. THE Admin_Panel SHALL use the standardized dialog component (as defined in Requirement 13) for all create and edit operations across Banners, Coupons, and Media screens.
5. THE Admin_Panel SHALL display the BreadcrumbsWithHeading page header on each screen (Banners, Coupons, Media) with the screen title, breadcrumb trail, and a primary action button (New Banner, New Coupon, Upload Image respectively) positioned in the trailing slot.
6. WHEN the Delete action is triggered on any item in Banners, Coupons, or Media screens, THE Admin_Panel SHALL display a confirmation dialog using the standardized dialog component with a destructive-variant confirm button before performing the deletion.
7. THE Admin_Panel SHALL display the standardized loading (Skeleton_Screen), error (Error_State with retry button), and empty (Empty_State with descriptive message and action button) states on the Banners, Coupons, and Media screens as defined in Requirement 15.

---

### Requirement 13: Dialog and Modal Component

**User Story:** As a developer, I want a standardized dialog component, so that all modal interactions share consistent structure, sizing, and behavior.

#### Acceptance Criteria

1. THE Component_Library SHALL provide a Dialog widget with a fixed maximum width of 560px, border radius xl, and consistent internal padding (24px).
2. THE Component_Library SHALL render dialog headers with a title (text lg, w600), an optional subtitle (text sm, secondary color), and a close icon button.
3. THE Component_Library SHALL render dialog footers with right-aligned action buttons using the standardized button components with consistent spacing (12px gap).
4. WHEN a dialog is opened, THE Component_Library SHALL apply a fade-in animation with a duration of 200ms, and WHEN a dialog is closed, SHALL apply a fade-out animation with a duration of 150ms.
5. THE Component_Library SHALL render a semi-transparent backdrop (black at 40% alpha) behind the dialog.
6. WHEN the user taps the backdrop or the close icon button, THE Component_Library SHALL dismiss the dialog.
7. IF the dialog content exceeds the available viewport height, THEN THE Component_Library SHALL make the content area scrollable while keeping the header and footer fixed in position.

---

### Requirement 14: Form Input Components

**User Story:** As a developer, I want standardized form input components, so that all forms across the panel share consistent styling and validation patterns.

#### Acceptance Criteria

1. THE Component_Library SHALL provide a TextInput widget with a height of 36px, border radius md, a 1px border using the border token color, a 2px focus border using the primary color, horizontal content padding of 12px, and placeholder text styled with text size base and secondary text color.
2. THE Component_Library SHALL provide a SelectInput (dropdown) widget matching the TextInput height (36px), border radius, border styling, and content padding, displaying a maximum of 6 visible items in the dropdown overlay before scrolling.
3. WHEN a form field has a validation error, THE Component_Library SHALL display the error message below the field with a 4px top spacing, in error color, with text size xs, limited to a maximum of 2 lines.
4. THE Component_Library SHALL provide form field labels with text size sm, font weight w500, and a 4px bottom margin from the input.
5. THE Component_Library SHALL provide a SearchInput variant with a leading search icon (20px), and a 300ms debounce on the onChange callback.
6. WHEN a form input is in the disabled state, THE Component_Library SHALL render the input with a reduced opacity of 0.5, a filled background using the gray50 token, and SHALL ignore all user interaction.

---

### Requirement 15: Loading, Error, and Empty States

**User Story:** As a user, I want clear visual feedback for loading, error, and empty states, so that I understand the current status of any data view.

#### Acceptance Criteria

1. WHEN data is loading, THE Admin_Panel SHALL display Skeleton_Screen placeholders with a shimmer animation cycling every 1.5 seconds instead of a plain CircularProgressIndicator.
2. THE Admin_Panel SHALL provide skeleton variants matching: table rows (5 horizontal bar placeholders), KPI cards (rectangular blocks matching KPI_Card dimensions), and chart areas (a single rectangular block matching the chart container height).
3. WHEN a data fetch fails, THE Admin_Panel SHALL display an Error_State containing: an error icon (24px, error color), a title "Something went wrong", a user-friendly error description (text sm, secondary color, maximum 150 characters with truncation via ellipsis), and a "Retry" button using the secondary button variant.
4. WHEN the "Retry" button in an Error_State is pressed, THE Admin_Panel SHALL re-invoke the failed data fetch and display the Skeleton_Screen loading state while the request is in progress.
5. WHEN a data list is empty, THE Admin_Panel SHALL display an Empty_State containing: an illustrative icon or SVG (48px), a title identifying the entity type with no results (e.g., "No orders found"), a subtitle suggesting a next step or explaining why the list may be empty (text sm, secondary color), and an optional action button relevant to the entity type.
6. THE Admin_Panel SHALL NOT display raw error strings, stack traces, or exception type names (e.g., "Error: $err", "SocketException") to the user.

---

### Requirement 16: Responsive Layout

**User Story:** As an administrator, I want the panel to adapt to different screen sizes, so that I can use the panel on tablets and smaller desktop monitors.

#### Acceptance Criteria

1. THE Admin_Panel SHALL define responsive breakpoints: compact (below 768px), medium (768px to 1199px), and expanded (1200px and above).
2. WHILE the viewport width is below 768px, THE Admin_Panel SHALL collapse the Sidebar_Navigation into a hamburger menu accessible via an icon button in the Header_Bar, and WHEN the hamburger icon is tapped, SHALL display the sidebar as a drawer overlay.
3. WHILE the viewport width is between 768px and 1199px, THE Admin_Panel SHALL collapse the Sidebar_Navigation to an icon-only rail (width 64px) with tooltips on hover showing the navigation item label.
4. WHILE the viewport width is 1200px or above, THE Admin_Panel SHALL display the full Sidebar_Navigation at 260px width.
5. THE Admin_Panel SHALL adjust KPI card grid columns: 4 columns on expanded, 2 columns on medium, 1 column on compact.
6. THE Admin_Panel SHALL allow horizontal scrolling for data tables on viewports narrower than 1000px (the table minimum width).
7. THE Admin_Panel SHALL adjust content area padding: 32px on expanded, 24px on medium, 16px on compact.

---

### Requirement 17: Route Transitions

**User Story:** As a user, I want smooth transitions between screens, so that navigation feels polished and intentional.

#### Acceptance Criteria

1. WHEN navigating between routes within the ShellRoute, THE Admin_Panel SHALL apply a fade transition with a duration of 200ms and an easeInOut curve.
2. WHEN navigating to or from the login screen, THE Admin_Panel SHALL apply a fade transition with a duration of 300ms and an easeInOut curve.
3. THE Admin_Panel SHALL NOT apply slide, scale, rotation, or bounce transition animations to any route navigation.
4. WHEN the user navigates using the browser back or forward buttons, THE Admin_Panel SHALL apply the same fade transition as forward navigation within the ShellRoute.

---

### Requirement 18: Dark Mode Support

**User Story:** As an administrator, I want a dark mode option, so that I can use the panel comfortably in low-light environments.

#### Acceptance Criteria

1. THE Design_System SHALL define a dark color scheme with: dark surface (gray 900-level), dark background (gray 950-level), light text (gray 100-level), adjusted semantic colors (success, warning, error, info) meeting a minimum 4.5:1 contrast ratio against the dark surface, and dark-mode-specific border (gray 700-level) and elevation tokens.
2. THE Admin_Panel SHALL provide a theme toggle control in the Header_Bar profile section that displays the current mode via a sun icon (light mode active) or moon icon (dark mode active).
3. WHEN the user toggles dark mode, THE Admin_Panel SHALL apply the selected theme to all visible components within the same frame (no page reload required) and persist the preference to local storage.
4. IF no theme preference is stored in local storage, THEN THE Admin_Panel SHALL default to the light theme.
5. THE Admin_Panel SHALL ensure all text meets WCAG 2.1 AA contrast ratio (4.5:1 for normal text, 3:1 for large text) in both light and dark modes.
6. WHEN the Admin_Panel loads with a previously stored theme preference, THE Admin_Panel SHALL apply the stored theme before rendering the first visible frame.

---

### Requirement 19: Login Screen Refinement

**User Story:** As an administrator, I want a polished login experience, so that the first interaction with the panel feels professional and trustworthy.

#### Acceptance Criteria

1. THE Admin_Panel SHALL display the login screen with a dark gradient background, a centered glassmorphic card (backdrop-blur filter, semi-transparent fill, and a 1px border at 10% white opacity), and the application brand mark centered above the form title.
2. THE Admin_Panel SHALL NOT render decorative background shapes (circles, blobs, or abstract ornaments) on the login screen.
3. THE Admin_Panel SHALL replace all deprecated `withOpacity` calls in the login screen with `Color.withValues(alpha: value)`.
4. WHEN login credentials are invalid, THE Admin_Panel SHALL display an inline error message below the form fields within the glassmorphic card, styled with the theme error color at 14px text size, and the message SHALL remain visible until the user modifies either input field or resubmits the form.
5. WHEN the login request is in progress, THE Admin_Panel SHALL disable the submit button and display a loading spinner within the button in place of the button label text.
6. THE Admin_Panel SHALL validate the email field contains a non-empty value with at least one `@` character followed by at least one `.` character, and validate that the password field is non-empty, before submitting the login request.
7. IF email or password validation fails, THEN THE Admin_Panel SHALL display the corresponding validation error message inline below the respective field and SHALL NOT submit the login request.

---

### Requirement 20: Accessibility Compliance

**User Story:** As a user with assistive technology, I want the admin panel to be accessible, so that I can operate all features using keyboard navigation and screen readers.

#### Acceptance Criteria

1. THE Admin_Panel SHALL provide semantic labels (Semantics widget or tooltip) for all icon-only buttons and interactive elements, where each label describes the action or purpose of the element (e.g., "Close dialog", "Delete order", "Toggle sidebar").
2. THE Admin_Panel SHALL support full keyboard navigation including: Tab/Shift+Tab to move between interactive elements in logical reading order (sidebar, header, then main content top-to-bottom), Enter/Space to activate buttons and toggles, Escape to close dialogs and menus, and Arrow keys to navigate within composite widgets (table rows, tab bars, dropdown options).
3. THE Admin_Panel SHALL ensure all interactive elements have a minimum touch target size of 44x44 pixels.
4. THE Admin_Panel SHALL ensure focus indicators are visible on all focusable elements using a 2px primary-colored outline with a 2px offset from the element edge, and the outline color SHALL maintain a minimum 3:1 contrast ratio against adjacent background colors in both light and dark modes.
5. THE Admin_Panel SHALL apply Flutter Semantics to identify: data tables with row and column header relationships, the Sidebar_Navigation as a navigation landmark, form controls with their associated labels and validation states (valid, invalid with error description), and buttons with their enabled/disabled state.
6. WHEN a dialog is opened, THE Admin_Panel SHALL move focus to the first focusable element within the dialog, constrain Tab cycling within the dialog content, and return focus to the triggering element when the dialog is closed.
7. WHEN data content changes dynamically (table filtering, sorting, pagination, or form validation errors), THE Admin_Panel SHALL announce the change to assistive technology via a live-region semantic (Semantics with liveRegion property) within 500ms of the change occurring.
8. WHEN a screen reader is active, THE Admin_Panel SHALL announce status messages (success confirmations, error notifications, loading states) without requiring the user to navigate to the message location.

---

### Requirement 21: Code Quality and Deprecation Cleanup

**User Story:** As a developer, I want the codebase free of deprecated API usage and lint warnings, so that the project remains maintainable and forward-compatible.

#### Acceptance Criteria

1. THE Admin_Panel SHALL replace all instances of `Color.withOpacity()` with `Color.withValues(alpha: value)` across all Dart files within the admin_app package.
2. THE Admin_Panel SHALL remove all unused imports identified by the Dart analyzer across all Dart files within the admin_app package.
3. THE Admin_Panel SHALL fix all analyzer information-level warnings (including but not limited to unnecessary underscores, missing block statements, and unnecessary type annotations) by correcting the source code patterns that cause them.
4. THE Admin_Panel SHALL consolidate the two competing sidebar implementations (core/widgets/layouts/sidebar.dart and core/widgets/navigation/app_shell.dart) into a single Sidebar_Navigation component, removing the unused file and updating all references to use the consolidated component.
5. WHEN `dart analyze` is run against the admin_app package with the project's configured analysis_options.yaml, THE Admin_Panel SHALL produce zero warnings at the info level or above.
6. WHEN the sidebar consolidation is complete, THE Admin_Panel SHALL preserve all existing navigation routes and menu items that were available across both previous sidebar implementations.
