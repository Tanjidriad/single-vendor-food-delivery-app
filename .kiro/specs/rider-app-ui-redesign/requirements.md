# Requirements Document

## Introduction

This feature is a UI/UX redesign of the existing Flutter rider app (`apps/rider_app`) for a single-vendor restaurant food delivery platform. The redesign brings the rider experience in line with modern courier apps (Foodpanda, Uber Eats) while preserving the existing teal brand identity and light/dark theming.

The scope covers the visual and interaction redesign of the four core flows (home/shift, incoming order, active delivery, earnings) plus the realtime GPS broadcast wiring that is directly required for the redesigned live-tracking UI to function. It also introduces a map abstraction layer so the planned migration from Mapbox to the Google Maps API remains a contained change.

The work is built on the current architecture: Flutter, Riverpod `NotifierProvider`s for state, `go_router` for navigation, and a Socket.IO client (`SocketService`) for realtime events. The redesign does not change backend contracts and does not perform the Mapbox-to-Google-Maps migration itself; it only prepares the codebase so that migration is isolated.

### In Scope

- Persistent draggable home bottom sheet replacing the static bottom pill, with real earnings data
- Animated "GO" online/offline centerpiece control
- Redesigned incoming order screen (animated countdown ring, earnings-first layout, two-leg trip summary, swipe-to-accept)
- Redesigned active delivery screen (horizontal step indicator, external navigation handoff, swipe-to-confirm)
- Real call/message actions and a defined chat entry flow
- Rider live GPS broadcast during active delivery (wiring `sendLocation`/`joinOrderRoom`)
- Haptics and sound/vibration feedback on order arrival and status changes
- Header rider profile/avatar entry and logout-behind-confirmation
- Brand-consistent skeleton loaders, empty states, and error states
- A map abstraction layer that keeps map-SDK-specific types out of screens

### Out of Scope (Non-Goals)

- Backend redesign or changes to API/socket contracts
- The actual Mapbox-to-Google-Maps SDK migration (only the abstraction enabling it)
- Changes to the brand palette or the existing light/dark theme tokens

## Glossary

- **Rider_App**: The Flutter rider application (`apps/rider_app`) being redesigned.
- **Rider**: The authenticated courier using the Rider_App.
- **Home_Sheet**: The persistent, draggable bottom sheet on the home screen that overlays the map and exposes shift status and earnings.
- **GO_Control**: The animated online/offline centerpiece control on the home screen.
- **Online_Status**: The boolean shift state held by `isOnlineProvider`, indicating whether the Rider is available to receive assignments.
- **Incoming_Order_Screen**: The screen shown when a new delivery assignment arrives.
- **Countdown_Ring**: The animated circular progress indicator that visualizes the remaining time to respond to an assignment.
- **Swipe_Action**: A slide-to-confirm control requiring the Rider to drag a handle across a track to trigger an action.
- **Active_Delivery_Screen**: The screen shown while the Rider is fulfilling an accepted order.
- **Step_Indicator**: The horizontal progress indicator showing the delivery stages: Restaurant, Pickup, Customer, Delivered.
- **Delivery_Step**: The integer stage held by `deliveryStepProvider` (0 = heading to restaurant, 1 = at restaurant/pickup, 2 = heading to customer).
- **Navigate_Action**: The control that hands off turn-by-turn navigation to an external app (Google Maps or Waze).
- **Socket_Service**: The Socket.IO client wrapper (`SocketService`) handling realtime events.
- **Location_Broadcast**: The act of emitting the Rider's GPS position to the backend via `Socket_Service.sendLocation`.
- **Map_View**: The reusable map widget (`AppMapView`) that renders the map, route, and markers.
- **Map_Abstraction**: The interface layer that exposes map functionality to screens using SDK-neutral types (latitude/longitude and route point lists) instead of Mapbox types.
- **Geo_Point**: An SDK-neutral coordinate value carrying latitude and longitude, used in place of the Mapbox `Position` type at screen boundaries.
- **Earnings_Summary**: The aggregated earnings data (today's total, trip count, acceptance rate, hours online, recent deliveries) retrieved from the earnings endpoint.
- **Skeleton_Loader**: A shimmer placeholder shown while data is loading, consistent with the customer app's shimmer language (`AppShimmerEffect`).
- **Empty_State**: A view shown when a data set is successfully loaded but contains no items.
- **Error_State**: A view shown when a data request fails, offering a retry affordance.
- **Profile_Entry**: The header control that opens the Rider's profile/account view.

## Requirements

### Requirement 1: Persistent Draggable Home Bottom Sheet

**User Story:** As a Rider, I want a draggable bottom sheet on the home screen that shows my live earnings and shift stats over the map, so that I can monitor my performance without leaving the map view.

#### Acceptance Criteria

1. THE Rider_App SHALL render the Home_Sheet as a persistent draggable sheet overlaying the Map_View on the home screen.
2. WHILE the Home_Sheet is collapsed, THE Rider_App SHALL display the GO_Control, today's total earnings, and today's trip count.
3. WHEN the Rider drags the Home_Sheet toward its expanded position, THE Rider_App SHALL expand the sheet and display the earnings breakdown, acceptance rate, hours online, and recent deliveries.
4. THE Rider_App SHALL populate the Home_Sheet earnings values from the Earnings_Summary returned by the earnings endpoint.
5. WHILE the Earnings_Summary is loading, THE Rider_App SHALL display Skeleton_Loaders in place of the earnings values.
6. IF the Earnings_Summary request fails, THEN THE Rider_App SHALL display an Error_State with a retry control inside the Home_Sheet.
7. WHEN the Rider activates the retry control, THE Rider_App SHALL re-request the Earnings_Summary.
8. WHEN the Rider drags the Home_Sheet handle, THE Rider_App SHALL animate the sheet between its collapsed and expanded positions.

### Requirement 2: Animated GO Online/Offline Control

**User Story:** As a Rider, I want a large animated GO control to toggle my availability, so that going online feels deliberate and my current status is unmistakable.

#### Acceptance Criteria

1. THE Rider_App SHALL display the GO_Control as the centerpiece control of the Home_Sheet.
2. WHEN the Rider activates the GO_Control, THE Rider_App SHALL send the new Online_Status to the rider-online endpoint before updating `isOnlineProvider`.
3. WHEN the rider-online request succeeds, THE Rider_App SHALL update `isOnlineProvider` to the new Online_Status.
4. WHILE the rider-online request is in progress, THE Rider_App SHALL display a loading indicator on the GO_Control and SHALL ignore further activations of the GO_Control.
5. IF the rider-online request fails, THEN THE Rider_App SHALL retain the previous Online_Status and SHALL display an error message.
6. WHILE Online_Status is true, THE Rider_App SHALL display the GO_Control with the online color treatment and a pulse-and-glow animation over the map.
7. WHILE Online_Status is false, THE Rider_App SHALL display the GO_Control in a dimmed offline treatment and SHALL dim the map.
8. WHEN Online_Status transitions from false to true, THE Rider_App SHALL play a color-sweep transition animation on the GO_Control.

### Requirement 3: Redesigned Incoming Order Screen

**User Story:** As a Rider, I want a clear incoming order screen that shows my earnings first with an animated countdown and a swipe-to-accept control, so that I can decide on an order quickly and confidently.

#### Acceptance Criteria

1. WHEN a new assignment arrives WHILE no active assignment and no active order exist, THE Rider_App SHALL display the Incoming_Order_Screen.
2. THE Incoming_Order_Screen SHALL display the estimated payout as the most visually prominent value.
3. THE Incoming_Order_Screen SHALL display a two-leg trip summary showing the restaurant pickup leg and the customer dropoff leg, each with its own distance.
4. THE Incoming_Order_Screen SHALL render a Countdown_Ring around the primary action that animates from full to empty over the assignment response window.
5. WHEN the remaining response time reaches or falls below 10 seconds, THE Incoming_Order_Screen SHALL display the Countdown_Ring in the warning color treatment.
6. WHEN the Rider completes the accept Swipe_Action, THE Rider_App SHALL call the accept-assignment endpoint and navigate to the Active_Delivery_Screen.
7. THE Incoming_Order_Screen SHALL provide a secondary reject control distinct from the accept Swipe_Action.
8. WHEN the Rider activates the reject control, THE Rider_App SHALL call the reject-assignment endpoint and return to the home screen.
9. IF the response window expires before the Rider responds, THEN THE Rider_App SHALL clear the active assignment and return to the home screen.
10. IF the accept-assignment request fails, THEN THE Incoming_Order_Screen SHALL display an error message and SHALL re-enable the accept Swipe_Action.

### Requirement 4: Redesigned Active Delivery Screen

**User Story:** As a Rider, I want a step-by-step active delivery screen with external navigation and swipe-to-confirm status changes, so that I can fulfill the delivery hands-free and avoid accidental status changes.

#### Acceptance Criteria

1. THE Active_Delivery_Screen SHALL display a horizontal Step_Indicator with the stages Restaurant, Pickup, Customer, and Delivered.
2. THE Active_Delivery_Screen SHALL highlight the Step_Indicator stage that corresponds to the current Delivery_Step.
3. THE Active_Delivery_Screen SHALL display a Navigate_Action button for the current destination.
4. WHEN the Rider activates the Navigate_Action, THE Rider_App SHALL open the current destination coordinates in an external navigation app (Google Maps or Waze).
5. IF no external navigation app is available, THEN THE Rider_App SHALL display a message indicating that no navigation app was found.
6. WHEN the Rider completes the confirm Swipe_Action at Delivery_Step 0, THE Rider_App SHALL update the order status to PICKED_UP and advance Delivery_Step to 1.
7. WHEN the Rider completes the confirm Swipe_Action at Delivery_Step 1, THE Rider_App SHALL update the order status to ON_THE_WAY and advance Delivery_Step to 2.
8. WHEN the Rider completes the confirm Swipe_Action at Delivery_Step 2, THE Rider_App SHALL present the proof-of-delivery flow.
9. WHEN the Rider submits a valid delivery PIN, THE Rider_App SHALL complete the order, clear the active order state, and return to the home screen.
10. IF an order status update request fails, THEN THE Active_Delivery_Screen SHALL display an error message and SHALL retain the current Delivery_Step.

### Requirement 5: Real Call and Message Actions

**User Story:** As a Rider, I want the call and message controls to actually contact the customer, so that I can resolve delivery issues directly.

#### Acceptance Criteria

1. WHERE the active order includes a customer phone number, THE Active_Delivery_Screen SHALL display an enabled call control.
2. WHEN the Rider activates the call control, THE Rider_App SHALL launch the device dialer with a `tel:` URI for the customer phone number.
3. THE Active_Delivery_Screen SHALL provide a customer chat entry distinct from the call control.
4. WHEN the Rider activates the message control, THE Rider_App SHALL open the defined chat entry for the active order.
5. WHERE the active order does not include a customer phone number, THE Active_Delivery_Screen SHALL hide the call control.
6. IF the device cannot launch the dialer, THEN THE Rider_App SHALL display a message indicating the call could not be started.

### Requirement 6: Rider Live GPS Broadcast During Active Delivery

**User Story:** As a customer waiting for my order, I want the rider's live location broadcast during delivery, so that the customer app can show the rider moving on the map in real time.

#### Acceptance Criteria

1. WHEN the Rider accepts an assignment, THE Rider_App SHALL join the order room for the active order via `Socket_Service.joinOrderRoom`.
2. WHILE an active order exists, THE Rider_App SHALL broadcast the Rider's location via `Socket_Service.sendLocation` each time a new GPS position is received, regardless of whether the order room join has completed.
3. THE Rider_App SHALL include the active order identifier, latitude, longitude, and heading in each Location_Broadcast.
4. WHEN the active order is completed or cleared, THE Rider_App SHALL stop broadcasting the Rider's location.
5. WHILE no active order exists, THE Rider_App SHALL NOT broadcast the Rider's location.
6. WHILE an active order exists, THE Active_Delivery_Screen SHALL display a directional rider marker on the Map_View that reflects the Rider's latest position and heading.
7. IF the Socket_Service is disconnected when a position is received, THEN THE Rider_App SHALL attempt to reconnect before the next Location_Broadcast.

### Requirement 7: Haptic and Sound Feedback

**User Story:** As a Rider, I want haptic and sound feedback on new orders and status changes, so that I notice events while riding without staring at the screen.

#### Acceptance Criteria

1. WHEN a new assignment arrives, THE Rider_App SHALL trigger a device vibration and play an alert sound.
2. WHEN the Rider completes a confirm Swipe_Action that changes the order status, THE Rider_App SHALL trigger haptic feedback.
3. WHEN the Rider completes the accept Swipe_Action, THE Rider_App SHALL trigger haptic feedback.
4. WHERE the device has muted notification sound, THE Rider_App SHALL trigger the device vibration for a new assignment.
5. WHERE haptic feedback is unavailable on the device, THE Rider_App SHALL continue the corresponding action without interruption.

### Requirement 8: Profile Entry and Confirmed Logout

**User Story:** As a Rider, I want a profile entry in the header and a logout confirmation, so that I can access my account and avoid logging out by accident.

#### Acceptance Criteria

1. THE Rider_App SHALL display a Profile_Entry with the Rider's avatar in the home screen header.
2. WHEN the Rider activates the Profile_Entry, THE Rider_App SHALL open the Rider profile view.
3. THE Rider profile view SHALL provide a logout control.
4. WHEN the Rider activates the logout control, THE Rider_App SHALL display a confirmation prompt before logging out.
5. WHEN the Rider confirms the logout prompt AND the logout succeeds, THE Rider_App SHALL log the Rider out and navigate to the login screen.
6. IF the logout request fails, THEN THE Rider_App SHALL retain the current session, display an error message, and remain on the current screen.
7. WHEN the Rider dismisses the logout prompt, THE Rider_App SHALL retain the current session and remain on the current screen.

### Requirement 9: Skeleton Loaders, Empty States, and Error States

**User Story:** As a Rider, I want consistent loading, empty, and error views across the app, so that the app feels polished and I always understand what is happening.

#### Acceptance Criteria

1. WHILE any remote data set is loading for the first time, THE Rider_App SHALL display Skeleton_Loaders consistent with the customer app's shimmer language.
2. WHEN a data request succeeds with no items, THE Rider_App SHALL display an Empty_State describing the absence of data.
3. IF a data request fails, THEN THE Rider_App SHALL display an Error_State with the failure reason and a retry control.
4. WHEN the Rider activates a retry control in an Error_State, THE Rider_App SHALL re-request the corresponding data.
5. THE Rider_App SHALL render Skeleton_Loaders, Empty_States, and Error_States using the existing teal brand palette in both light and dark themes.

### Requirement 10: Map Abstraction Layer

**User Story:** As a developer, I want all map-SDK-specific types kept out of the screens, so that the upcoming Mapbox-to-Google-Maps migration is contained to the abstraction layer.

#### Acceptance Criteria

1. THE Map_Abstraction SHALL expose map functionality to screens using Geo_Point values and route point lists rather than Mapbox-specific types.
2. THE Incoming_Order_Screen SHALL pass locations and route points to the Map_View using Geo_Point values only.
3. THE Active_Delivery_Screen SHALL pass locations and route points to the Map_View using Geo_Point values only.
4. THE Rider_App SHALL confine all imports of `mapbox_maps_flutter` to the Map_Abstraction and its implementation files.
5. THE Map_Abstraction SHALL provide conversion between Geo_Point values and the underlying map SDK coordinate type within the implementation layer.
6. WHERE a screen requests a route between two Geo_Point values, THE Map_Abstraction SHALL return route points as Geo_Point values.

### Requirement 11: Preserved Brand and Theming

**User Story:** As a Rider, I want the redesigned app to keep the familiar teal brand in light and dark mode, so that the experience stays recognizable and comfortable in all lighting.

#### Acceptance Criteria

1. THE Rider_App SHALL apply the existing teal brand palette across all redesigned screens.
2. WHILE the device is in light mode, THE Rider_App SHALL render redesigned screens using the light theme tokens.
3. WHILE the device is in dark mode, THE Rider_App SHALL render redesigned screens using the dark theme tokens.
4. THE Rider_App SHALL apply the active theme to all new components, including the Home_Sheet, GO_Control, Step_Indicator, and Swipe_Actions.
