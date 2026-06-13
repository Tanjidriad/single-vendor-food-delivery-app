# Implementation Plan: Rider App UI Redesign

## Overview

This plan implements the rider app UI/UX redesign in the existing Flutter app (`apps/rider_app`) using the current architecture (Flutter, Riverpod `NotifierProvider`s, `go_router`, Socket.IO `SocketService`). Work proceeds bottom-up: first the SDK-neutral map abstraction and pure-logic view models, then shared widgets and services, then the redesigned screens, and finally the realtime/feedback wiring that ties everything together.

Property-based tests use the `glados` package (idiomatic Dart PBT) and target the pure-logic core defined in the design's Correctness Properties. Widget/unit/integration tests use `flutter_test` with `ProviderScope` overrides and `mocktail` mocks. The map-abstraction architectural constraints are verified with static import/smoke checks. All test sub-tasks are marked optional with `*`.

## Tasks

- [x] 1. Add dependencies and test scaffolding
  - [x] 1.1 Add runtime dependencies to `apps/rider_app/pubspec.yaml`
    - Add `shimmer`, `url_launcher`, and `audioplayers` under `dependencies`
    - Run `flutter pub get` and confirm resolution
    - _Requirements: 1.5, 4.4, 5.2, 7.1, 9.1_

  - [x] 1.2 Add test dev dependencies and test directory layout
    - Add `glados` and `mocktail` under `dev_dependencies` in `pubspec.yaml`
    - Create `apps/rider_app/test/` structure (`core/`, `features/`, `helpers/`) and a shared `ProviderScope`/mock helper file
    - _Requirements: 1.4, 2.2_

- [x] 2. Build the map abstraction layer (SDK-neutral boundary)
  - [x] 2.1 Create SDK-neutral coordinate and marker types
    - Add `core/map/geo_point.dart` (`GeoPoint` with value equality and `hashCode`)
    - Add `core/map/map_marker.dart` (`MapMarker`, `MapMarkerKind` including `rider` with `headingDegrees`)
    - _Requirements: 10.1, 6.6_

  - [x] 2.2 Implement Mapbox coordinate conversions (implementation layer only)
    - Add `core/map/mapbox/coordinate_conversions.dart` with `GeoPoint.toPosition()` and `Position.toGeoPoint()` extensions
    - This is the only place allowed to import `mapbox_maps_flutter` for conversion; encapsulate the `Position(lng, lat)` axis ordering
    - _Requirements: 10.5_

  - [x] 2.3 Write property test for GeoPoint ↔ SDK coordinate round-trip
    - **Property 14: GeoPoint ↔ SDK coordinate round-trip**
    - **Validates: Requirements 10.5**
    - Generate coordinate extremes (poles, antimeridian, negative lat/lng); assert `toPosition().toGeoPoint()` equals the original within tolerance

  - [x] 2.4 Define `RouteService` and `LocationService` abstractions
    - Add `core/map/route_service.dart` (`getRoute(GeoPoint, GeoPoint) -> Future<List<GeoPoint>>`)
    - Add `core/map/location_service.dart` (`positionStream() -> Stream<GeoPoint>`, `currentPosition() -> Future<GeoPoint?>`)
    - _Requirements: 10.1, 10.6_

  - [x] 2.5 Implement `MapboxRouteService`
    - Add `core/map/mapbox/mapbox_route_service.dart` wrapping the existing `MapboxDirectionsService`, mapping `Position` results to `GeoPoint`
    - _Requirements: 10.6_

  - [x] 2.6 Write property test for route conversion
    - **Property 15: Route conversion returns SDK-neutral points**
    - **Validates: Requirements 10.6**
    - Mock SDK directions; assert element-wise `GeoPoint` conversion preserves length and each lat/lng

  - [x] 2.7 Implement `GeolocatorLocationService` and migrate `location_provider.dart` to GeoPoint
    - Add `core/map/mapbox/geolocator_location_service.dart` wrapping existing geolocator logic, returning `GeoPoint`, preserving the Dhaka fallback
    - Update `features/orders/presentation/providers/location_provider.dart` to expose `locationStreamProvider` of `GeoPoint` and drop the Mapbox `Position` import
    - _Requirements: 10.1, 10.4_

  - [x] 2.8 Refactor `AppMapView` into an SDK-neutral facade
    - Update `core/widgets/map/app_map_view.dart` to accept `GeoPoint? initialCamera`, `List<GeoPoint>? route`, `List<MapMarker>? markers`
    - Add a private Mapbox implementation widget under `core/map/mapbox/` that converts and draws polylines/markers (including the directional rider marker)
    - _Requirements: 10.1, 10.4, 6.6_

  - [x] 2.9 Move Mapbox bootstrap out of `main.dart`
    - Add `core/map/mapbox/mapbox_bootstrap.dart` holding the access-token setup; invoke it from `main()` so `main.dart` no longer imports `mapbox_maps_flutter`
    - _Requirements: 10.4_

  - [x] 2.10 Migrate `route_provider.dart` to GeoPoint + RouteService
    - Update `features/orders/presentation/providers/route_provider.dart` (`RouteRequest`, `LiveRouteNotifier`, `liveRouteProvider`) to use `GeoPoint` and `RouteService`, removing the Mapbox import
    - _Requirements: 10.1, 10.6_

- [x] 3. Build pure-logic view models
  - [x] 3.1 Implement `EarningsSummary` and `EarningsEntry`
    - Add `features/earnings/data/earnings_summary.dart` with tolerant `fromJson` (optional fields degrade to null/`'--'`)
    - _Requirements: 1.4_

  - [x] 3.2 Write property test for earnings parsing
    - **Property 1: Earnings summary parsing maps fields**
    - **Validates: Requirements 1.4**
    - Generate payloads with optional fields present/absent; assert today-total, trip count, hours-online, recent-deliveries reflect payload and missing fields never throw

  - [x] 3.3 Implement `AssignmentView`
    - Add `features/orders/data/assignment_view.dart` parsing the assignment payload (payout, cash, two-leg distances, `expiresAt`, `pickupPoint`/`dropoffPoint` as `GeoPoint`)
    - _Requirements: 3.2, 3.3, 3.4_

  - [x] 3.4 Implement `ActiveOrderView`
    - Add `features/orders/data/active_order_view.dart` (`hasPhone`, `destinationForStep(step)`, `restaurantPoint`/`dropoffPoint` as `GeoPoint`)
    - _Requirements: 5.1, 5.5_

  - [x] 3.5 Write property test for call-control visibility
    - **Property 11: Call-control visibility tracks phone presence**
    - **Validates: Requirements 5.1, 5.5**
    - Generate empty/whitespace/non-empty phone strings; assert `hasPhone` is true iff phone is non-empty

  - [x] 3.6 Implement `DeliveryStateModel` and `CountdownState`
    - Add `features/orders/data/delivery_state_model.dart` (`stageForStep`, `statusForStep`, `nextStep`)
    - Add `features/orders/data/countdown_state.dart` (`CountdownState.from(remaining, total)` with clamped fraction and warning flag)
    - _Requirements: 4.2, 4.6, 4.7, 4.8, 3.4, 3.5_

  - [x] 3.7 Write property test for the delivery step state machine
    - **Property 8: Delivery step state machine is well-defined**
    - **Validates: Requirements 4.2, 4.6, 4.7, 4.8**
    - For steps {0,1,2}: assert correct stage, status (`0→PICKED_UP`, `1→ON_THE_WAY`), next step, and that step 2 yields no status (POD branch)

  - [x] 3.8 Write property test for countdown derivation
    - **Property 7: Countdown derivation is correct and monotonic**
    - **Validates: Requirements 3.4, 3.5**
    - For `T>0` and `r` in `[0,T]` (including 0, T, and the 10s boundary): assert `fraction == clamp(r/T, 0, 1)` and `isWarning == (r <= 10)`

- [x] 4. Build the shared feedback vocabulary widgets
  - [x] 4.1 Implement rider-local `AppShimmerEffect`
    - Add `core/widgets/feedback/app_shimmer_effect.dart` mirroring the customer app shimmer, themed from `AppColors` for light/dark
    - _Requirements: 9.1, 9.5_

  - [x] 4.2 Implement `EmptyStateView` and `ErrorStateView`
    - Add `core/widgets/feedback/empty_state_view.dart` (icon + message)
    - Add `core/widgets/feedback/error_state_view.dart` (failure reason + retry callback)
    - _Requirements: 9.2, 9.3, 9.4, 9.5_

  - [x] 4.3 Write widget tests for the feedback vocabulary
    - Verify skeleton/empty/error rendering and that retry invokes its callback
    - Verify teal palette tokens applied in both light and dark themes
    - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5_

- [x] 5. Build the reusable `SwipeAction`
  - [x] 5.1 Implement `SwipeAction`
    - Add `core/widgets/swipe_action.dart` (slide-to-confirm; fires `onConfirmed` only past threshold; handle springs back if `onConfirmed` throws; triggers haptics via `FeedbackService`); themed with active palette
    - _Requirements: 3.6, 4.6, 4.7, 7.2, 7.3, 11.4_

  - [x] 5.2 Write widget test for `SwipeAction`
    - Verify confirm fires only past threshold, spring-back on throw, and theme application
    - _Requirements: 3.6, 4.6, 11.4_

- [x] 6. Build domain services
  - [x] 6.1 Implement `NavigationLauncher` with pure URI builders
    - Add `core/services/navigation_launcher.dart` (`openExternalNavigation(GeoPoint)`, `dial(phone)`, plus pure `buildGeoUri` and `buildTelUri`); return false when no handler/launch fails
    - _Requirements: 4.4, 4.5, 5.2, 5.6_

  - [x] 6.2 Write property test for navigation URI builder
    - **Property 10: External-navigation URI encodes the destination**
    - **Validates: Requirements 4.4**
    - For any `GeoPoint`, assert `buildGeoUri` encodes that point's latitude and longitude

  - [x] 6.3 Write property test for dialer URI builder
    - **Property 12: Dialer URI encodes the phone number**
    - **Validates: Requirements 5.2**
    - For any phone string, assert `buildTelUri` produces a `tel:` URI encoding that number

  - [x] 6.4 Implement `FeedbackService`
    - Add `core/services/feedback_service.dart` (`onIncomingAssignment` = vibrate + alert sound; `onConfirm` = haptic); wrap all calls so a missing capability never throws; vibration attempted independently of sound
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

  - [x] 6.5 Implement location-broadcast decision and coordinator
    - Add `core/services/location_broadcast.dart` (`LocationBroadcast` model + pure `decideBroadcast(activeOrderId, position, heading)`)
    - Add `locationBroadcastProvider` that watches `activeOrderProvider` + `locationStreamProvider`, calls `SocketService.sendLocation` per position when an order is active, and `connect()`s if disconnected before the next broadcast
    - _Requirements: 6.2, 6.3, 6.4, 6.5, 6.7_

  - [x] 6.6 Write property test for the location-broadcast decision
    - **Property 13: Location-broadcast decision**
    - **Validates: Requirements 6.2, 6.3, 6.4, 6.5**
    - Assert a broadcast is returned iff an active order exists, carries order id + lat/lng/heading, and is independent of join completion

- [x] 7. Refactor earnings data layer and provider
  - [x] 7.1 Refactor `EarningsRepository` to surface typed failure
    - Update `features/earnings/data/earnings_repository.dart` to throw a typed `EarningsFailure(message)` instead of returning `null`, and return an `EarningsSummary`
    - _Requirements: 1.4, 1.6, 9.3_

  - [x] 7.2 Add `earningsSummaryProvider`
    - Add an `AsyncNotifier`/`FutureProvider` exposing `EarningsSummary` with error via `AsyncValue.error` and a refresh/retry method
    - _Requirements: 1.4, 1.7, 9.4_

  - [x] 7.3 Write unit test for earnings provider error/retry
    - Mock repository success, empty, and failure; assert loading→data, error surfaced, and retry re-requests
    - _Requirements: 1.6, 1.7, 9.3, 9.4_

- [x] 8. Build the GO online/offline control
  - [x] 8.1 Implement `RiderOnlineController`
    - Add a `Notifier`/controller that `PATCH`es `/users/rider/online` before updating `isOnlineProvider`, ignores re-entrant activations while in flight, and retains previous status on failure
    - _Requirements: 2.2, 2.3, 2.4, 2.5_

  - [x] 8.2 Write property tests for the rider-online toggle
    - **Property 2: Rider-online toggle requests before mutating state**
    - **Property 3: Successful toggle sets status to the target**
    - **Property 4: In-flight toggle ignores re-entrant activations**
    - **Property 5: Failed toggle retains the previous status**
    - **Validates: Requirements 2.2, 2.3, 2.4, 2.5**
    - Use an ordering/counting mock client across generated target statuses and N re-entrant activations

  - [x] 8.3 Implement `GoControl` widget
    - Add `features/shift/presentation/widgets/go_control.dart` (tap → controller; in-flight loading; online pulse-and-glow; offline dimmed; false→true color-sweep), themed via `AppColors`
    - _Requirements: 2.1, 2.4, 2.6, 2.7, 2.8, 11.4_

  - [x] 8.4 Write widget test for `GoControl`
    - Verify loading state ignores taps, online/offline treatments, and color-sweep on false→true
    - _Requirements: 2.4, 2.6, 2.7, 2.8_

- [x] 9. Build the Home Sheet and integrate into Home Screen
  - [x] 9.1 Implement `HomeSheet`
    - Add `features/shift/presentation/widgets/home_sheet.dart` as a persistent `DraggableScrollableSheet` over the map: collapsed (GoControl + today total + trip count), expanded (breakdown, acceptance rate, hours online, recent deliveries), shimmer while loading, inline `ErrorStateView` + retry on failure
    - _Requirements: 1.1, 1.2, 1.3, 1.5, 1.6, 1.7, 1.8, 11.4_

  - [x] 9.2 Integrate `HomeSheet` and `ProfileEntry` into `HomeScreen`
    - Update `features/shift/presentation/screens/home_screen.dart` to layer `HomeSheet` over `AppMapView`, replacing the static bottom pill/`Switch`; dim the map while offline; add the header `ProfileEntry`
    - _Requirements: 1.1, 2.7, 8.1, 8.2_

  - [x] 9.3 Write widget tests for the Home Sheet
    - Verify persistent/draggable over map, collapsed vs expanded content, skeletons, inline error + retry, and offline map dim
    - _Requirements: 1.1, 1.2, 1.3, 1.5, 1.6, 2.7_

- [x] 10. Redesign the Incoming Order Screen
  - [x] 10.1 Implement `CountdownRing`
    - Add `features/orders/presentation/widgets/countdown_ring.dart` (`CustomPainter` ring around a child; consumes `CountdownState`; warning color via `AppColors`)
    - _Requirements: 3.4, 3.5, 11.4_

  - [x] 10.2 Redesign `incoming_order_screen.dart`
    - Update `features/orders/presentation/screens/incoming_order_screen.dart`: earnings-first layout (payout most prominent), two-leg `TripLegSummary`, `CountdownRing` around the accept `SwipeAction`, distinct reject control, expiry clears assignment and returns home, accept failure re-enables swipe; on accept call accept endpoint, set active order, reset step, join order room, and `pushReplacement` to active delivery; pass map data as `GeoPoint`/`List<GeoPoint>` only
    - Implement the idle guard predicate (show only when `activeAssignmentProvider` and `activeOrderProvider` are both null)
    - _Requirements: 3.1, 3.2, 3.3, 3.6, 3.7, 3.8, 3.9, 3.10, 6.1, 10.2_

  - [x] 10.3 Write property test for the incoming-screen guard predicate
    - **Property 6: Incoming screen shown only when idle**
    - **Validates: Requirements 3.1**
    - Over all combinations of assignment/order presence, assert the screen is presented iff both are null

  - [x] 10.4 Write widget tests for the Incoming Order Screen
    - Verify payout prominence, two-leg summary, accept swipe → accept + navigate, distinct reject, expiry → clear + home, accept-failure re-enable
    - _Requirements: 3.2, 3.3, 3.6, 3.7, 3.8, 3.9, 3.10_

- [x] 11. Redesign the Active Delivery Screen
  - [x] 11.1 Implement `StepIndicator`
    - Add `features/orders/presentation/widgets/step_indicator.dart` (horizontal Restaurant → Pickup → Customer → Delivered, highlighting the stage from `DeliveryStateModel.stageForStep`), themed via `AppColors`
    - _Requirements: 4.1, 4.2, 11.4_

  - [x] 11.2 Implement `DeliveryProgressController`
    - Add a controller using `DeliveryStateModel`: on confirm, call the order-status update (`PICKED_UP`/`ON_THE_WAY`); advance step on success; retain step on failure; step 2 routes to proof-of-delivery
    - _Requirements: 4.6, 4.7, 4.8, 4.10_

  - [x] 11.3 Write property test for failed status-update step retention
    - **Property 9: Failed status update retains the delivery step**
    - **Validates: Requirements 4.10**
    - For steps {0,1}, when the update fails assert `deliveryStepProvider` is unchanged and an error is surfaced

  - [x] 11.4 Redesign `active_delivery_screen.dart`
    - Update `features/orders/presentation/screens/active_delivery_screen.dart`: `StepIndicator`, `NavigateAction` (external nav via `NavigationLauncher`, "no navigation app found" fallback), confirm `SwipeAction` driving `DeliveryProgressController`, retain existing `_ProofOfDeliverySheet` for step 2 (valid PIN completes order, clears state, returns home), call control shown only when phone present (`tel:` via launcher, dialer-failure message), chat entry distinct from call; map data as `GeoPoint` only
    - _Requirements: 4.1, 4.3, 4.4, 4.5, 4.6, 4.7, 4.8, 4.9, 4.10, 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 10.3_

  - [x] 11.5 Wire the directional rider marker
    - In `active_delivery_screen.dart`, pass a `rider`-kind `MapMarker` with `headingDegrees` from the latest position to `AppMapView`
    - _Requirements: 6.6_

  - [x] 11.6 Write widget tests for the Active Delivery Screen
    - Verify four-stage indicator, no-nav-app message, POD sheet presentation + valid-PIN completion, chat entry distinct from call, no-dialer message, call-control visibility
    - _Requirements: 4.1, 4.3, 4.5, 4.8, 4.9, 5.3, 5.4, 5.5, 5.6_

- [x] 12. Profile entry and confirmed logout
  - [x] 12.1 Implement `ProfileEntry`, `ProfileScreen`, and route
    - Add `ProfileEntry` (avatar control) and `features/profile/presentation/screens/profile_screen.dart` (rider identity + logout control); add the `/profile` route to `app_router.dart`/`route_paths.dart`
    - _Requirements: 8.1, 8.2, 8.3_

  - [x] 12.2 Implement confirmed logout
    - Add a confirmation dialog to the logout control; extend `AuthNotifier.logout` to surface failure; on confirm+success `go` to login, on failure retain session + show error + stay, on dismiss retain session + stay
    - _Requirements: 8.4, 8.5, 8.6, 8.7_

  - [x] 12.3 Write widget tests for profile and logout
    - Verify profile entry/avatar, logout control, confirmation prompt, confirmed-success → login, failure retains session, dismiss retains session
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6, 8.7_

- [ ] 13. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 14. Wire realtime feedback and GPS broadcast
  - [x] 14.1 Wire feedback and broadcast coordinator
    - In `home_screen.dart`, trigger `FeedbackService.onIncomingAssignment` from the same `ref.listen(incomingAssignmentStreamProvider)` site that pushes the incoming screen
    - Activate `locationBroadcastProvider` during active delivery so positions broadcast via `SocketService.sendLocation` (with reconnect on disconnect) and stop when the order clears
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.7, 7.1, 7.4_

  - [ ] 14.2 Write integration tests for realtime wiring
    - Verify join on accept, broadcast while active (independent of join completion), reconnect on disconnected position, stop on clear, and vibrate+sound on assignment arrival
    - _Requirements: 6.1, 6.2, 6.4, 6.7, 7.1, 7.4_

- [ ] 15. Enforce the map SDK boundary
  - [ ] 15.1 Add a static import/smoke check for the map abstraction
    - Add a repo-walking test that fails if any file outside `core/map/mapbox/` imports `mapbox_maps_flutter`, and assert the incoming/active screens reference only `GeoPoint`/`MapMarker`
    - _Requirements: 10.1, 10.2, 10.3, 10.4_

- [ ] 16. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional (tests/static checks) and can be skipped for a faster MVP; core implementation tasks are never optional.
- Each task references specific granular requirements for traceability.
- Property-based tests use `glados`, run a minimum of 100 iterations, and are tagged `// Feature: rider-app-ui-redesign, Property {n}: {text}`.
- Map-SDK containment (Req 10.4) is verified by a static import check rather than a property test.
- Backend and socket contracts are unchanged; Requirement 6 is wiring of existing `SocketService.joinOrderRoom`/`sendLocation`.

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1", "2.1", "3.1", "3.6"] },
    { "id": 1, "tasks": ["1.2", "2.2", "2.4", "3.3", "3.4", "4.1", "4.2", "6.1", "6.4"] },
    { "id": 2, "tasks": ["2.3", "2.5", "2.7", "2.8", "3.2", "3.5", "3.7", "3.8", "4.3", "5.1", "6.2", "6.3", "6.5", "7.1"] },
    { "id": 3, "tasks": ["2.6", "2.9", "2.10", "5.2", "6.6", "7.2", "8.1"] },
    { "id": 4, "tasks": ["7.3", "8.2", "8.3", "10.1", "11.1", "11.2", "12.1"] },
    { "id": 5, "tasks": ["8.4", "9.1", "11.3", "11.4", "12.2"] },
    { "id": 6, "tasks": ["9.2", "9.3", "10.2", "11.5", "11.6", "12.3"] },
    { "id": 7, "tasks": ["10.3", "10.4", "14.1"] },
    { "id": 8, "tasks": ["14.2", "15.1"] }
  ]
}
```
