# Mapbox → Google Maps Migration Plan

## Context

The WASABI food delivery platform uses Mapbox for maps across `customer_app` and `rider_app` (kitchen_app has no maps). The backend already uses Google Maps as primary with Mapbox as fallback. We're migrating fully to Google Maps for consistency, better pricing control, and to eliminate the Mapbox dependency.

**Key finding:** The rider app has excellent SDK-neutral abstractions (`GeoPoint`, `RouteService`, `LocationService`) with Mapbox isolated in a `core/map/mapbox/` directory — swapping is trivial. The customer app is tightly coupled to Mapbox with imports leaking into core widgets. It must be refactored first.

**Strategy: Refactor first, then swap.** Phase 0 brings the customer app up to the rider app's abstraction quality. Then both apps swap cleanly.

---

## Phase 0: Customer App Abstraction Refactor

**Goal:** Mirror the rider app's SDK-neutral pattern. No SDK change — Mapbox still runs behind the new abstractions.

### 0.1 — Create SDK-neutral types

Create `customer_app/lib/core/map/geo_point.dart`:
- Copy rider app's `GeoPoint` class (31-line immutable lat/lng value type)

Create `customer_app/lib/core/map/map_marker.dart`:
- `MapMarkerKind` enum: `rider`, `pickup`, `dropoff`, `generic`
- Immutable `MapMarker` with `GeoPoint point`, `MapMarkerKind kind`, `double? headingDegrees`
- Replaces the existing `AppMapMarker` (which uses raw lat/lng + string IDs)

Create `customer_app/lib/core/map/route_service.dart`:
- Abstract class: `Future<List<GeoPoint>> getRoute(GeoPoint start, GeoPoint end)`
- Add `Future<List<GeoPoint>> getRouteThrough(List<GeoPoint> waypoints)` (customer app uses multi-waypoint routing)

### 0.2 — Create Mapbox implementation directory

Create `customer_app/lib/core/map/mapbox/` and move existing code into it:

- Move `core/map/mapbox_directions_service.dart` → `core/map/mapbox/mapbox_directions_service.dart`
- Create `mapbox_route_service.dart` — wraps `MapboxDirectionsService`, implements `RouteService`, converts `GeoPoint`↔`AppMapRoutePoint`
- Create `coordinate_conversions.dart` — `GeoPoint.toPosition()` / `Position.toGeoPoint()` extensions
- Move the 415-line `core/widgets/map/app_map_view.dart` → `core/map/mapbox/mapbox_map_view.dart` (rename class to `MapboxMapView`, change API to accept `GeoPoint`/`MapMarker` instead of raw types)

### 0.3 — Rewrite the public facade

Rewrite `customer_app/lib/core/widgets/map/app_map_view.dart`:
- Strip all Mapbox imports — thin facade (~47 lines, matching rider app)
- Accept `GeoPoint? initialCamera`, `List<GeoPoint>? route`, `List<MapMarker>? markers`
- Delegate to `MapboxMapView` internally

### 0.4 — Migrate feature callers

Update screens/providers to use new SDK-neutral types:
- `features/orders/presentation/utils/tracking_map_markers.dart` — return `List<MapMarker>` + `GeoPoint`
- `features/orders/presentation/providers/tracking_route_provider.dart` — use `RouteService` abstraction instead of `MapboxDirectionsService` directly
- `features/orders/presentation/screens/order_tracking_screen.dart` — pass `GeoPoint`/`MapMarker` to `AppMapView`
- `features/checkout/presentation/screens/checkout_screen.dart` — same pattern
- `features/profile/presentation/widgets/add_address_sheet.dart` — same pattern

### 0.5 — Delete replaced types

- Delete `core/widgets/map/models/app_map_marker.dart` (replaced by `MapMarker`)
- Delete `core/map/models/app_map_route_point.dart` (replaced by `GeoPoint`)

**Verification:** Run all screens — identical behavior, zero visual changes. This is a pure refactor.

---

## Phase 1: Create Google Maps Implementations

**Goal:** Write Google Maps implementations side-by-side with Mapbox. Neither app switches yet.

### 1.1 — Add dependencies

Both `pubspec.yaml` files:
- Add `google_maps_flutter: ^2.10.0`
- Keep `mapbox_maps_flutter` temporarily (removed in Phase 2)

### 1.2 — Google Maps implementations (create in both apps)

Create `core/map/google/` directory in both apps:

**`google_map_view.dart`** (~200 lines):
- `GoogleMap` widget with `Set<Marker>`, `Set<Polyline>`, `CameraUpdate`
- Custom markers via `BitmapDescriptor.bytes()` — reuse existing Canvas-drawn PNG bitmap logic
- Rider heading: `Marker(rotation: headingDegrees)` — same convention as Mapbox `iconRotate`
- Camera bounds: `GoogleMapController.animateCamera(CameraUpdate.newLatLngBounds(...))`
- Polyline: `Polyline(points: [...], color: AppColors.primary, width: 5)`
- Simpler than Mapbox — declarative `Set<Marker>` (no annotation managers or lifecycle issues)

**`google_directions_service.dart`**:
- Calls `https://maps.googleapis.com/maps/api/directions/json?origin=lat,lng&destination=lat,lng&key=KEY`
- Decodes `routes[0].overview_polyline.points` (encoded polyline algorithm, ~30 lines inline)
- Supports `waypoints` parameter for multi-stop routing
- Returns `List<GeoPoint>`

**`google_route_service.dart`**:
- Implements `RouteService` abstract class
- Wraps `GoogleDirectionsService`

**`google_bootstrap.dart`**:
- Reads `GOOGLE_MAPS_API_KEY` from `--dart-define` or `.env`
- Exposes key for Directions API HTTP calls (the map widget key goes in platform config, not Dart)

### 1.3 — Relocate vendor-neutral location service

Move `rider_app/lib/core/map/mapbox/geolocator_location_service.dart` → `core/map/geolocator/geolocator_location_service.dart`
- This file uses the `geolocator` package (NOT Mapbox) but lives in the `mapbox/` directory
- Must be relocated before deleting `mapbox/` in Phase 2

---

## Phase 2: Swap Both Apps to Google Maps

**Goal:** Flip the switch. One commit per app for clean revert.

### 2.1 — Rider app swap (3 changes)

1. `core/widgets/map/app_map_view.dart` — change import from `mapbox_map_view` to `google_map_view`, change `MapboxMapView(...)` to `GoogleMapView(...)`
2. Route provider — return `GoogleRouteService()` instead of `MapboxRouteService()`
3. `main.dart` — remove `bootstrapMapbox()` call and import

### 2.2 — Customer app swap (3 changes)

1. `core/widgets/map/app_map_view.dart` — same swap as rider app
2. `tracking_route_provider.dart` — return `GoogleRouteService()` instead of `MapboxRouteService()`
3. `main.dart` — remove `MapboxOptions.setAccessToken(...)` block

### 2.3 — Remove Mapbox dependency

Both `pubspec.yaml` files:
- Remove `mapbox_maps_flutter: ^2.24.3`
- `flutter pub get`

### 2.4 — Delete Mapbox implementation files

- Delete `rider_app/lib/core/map/mapbox/` (entire directory, except `geolocator_location_service.dart` already relocated)
- Delete `customer_app/lib/core/map/mapbox/` (entire directory)

**Verification checklist:**
- Order tracking: 3 markers (restaurant/rider/delivery), polyline route, rider heading arrow rotates
- Camera: flyTo animation, bounds fitting with padding
- Checkout: map pin at delivery address
- Add address: map view at selected location
- Rider active delivery: markers, route, live GPS updates
- Rider incoming order: restaurant + delivery pins

---

## Phase 3: Backend Cleanup

**Goal:** Remove Mapbox fallback. Google is already primary.

### 3.1 — Remove Mapbox from MapsService

`backend/src/modules/delivery-fee/maps.service.ts`:
- Delete `if (mapboxToken)` block in `getRouteQuote()` — fallback chain becomes: Google → Haversine
- Delete Mapbox geocoding blocks in `geocode()` and `reverseGeocode()` — chain becomes: Google → Nominatim
- Change `RouteQuote.source` type from `'google' | 'mapbox' | 'haversine'` to `'google' | 'haversine'`

### 3.2 — Remove Mapbox config

- `backend/src/config/configuration.ts` — delete `mapboxAccessToken` line
- `backend/.env` and `.env.example` — remove `MAPBOX_ACCESS_TOKEN`

---

## Phase 4: Platform Config & Cleanup

### 4.1 — Android config

Both apps `android/app/src/main/AndroidManifest.xml`:

```xml
<meta-data android:name="com.google.android.geo.API_KEY"
           android:value="${GOOGLE_MAPS_API_KEY}" />
```

Both `build.gradle.kts` — read key from `local.properties`, inject via `manifestPlaceholders`.

Rider app — remove Mapbox `resValue` injection (lines 57-58 in `build.gradle.kts`).

### 4.2 — iOS config

Both apps `ios/Runner/AppDelegate.swift`:

```swift
import GoogleMaps
GMSServices.provideAPIKey("YOUR_KEY")
```

### 4.3 — Remove Mapbox tokens

- Remove `MAPBOX_ACCESS_TOKEN` from all `.env` / `.env.example` files
- Remove from `rider_app/android/local.properties`
- Remove any Mapbox Maven repository declarations in Gradle settings
- Update CI/CD: remove Mapbox token injection, add Google Maps API key

### 4.4 — Final audit

Run `grep -ri "mapbox" .` across entire repo. Every hit should be only in git history. Any remaining reference is a missed cleanup item.

Run `flutter clean && flutter pub get` in both apps. iOS: `cd ios && pod install`.

---

## Files Modified Summary

| Phase | App | Files |
|-------|-----|-------|
| 0 | customer_app | New: `core/map/geo_point.dart`, `map_marker.dart`, `route_service.dart`, `mapbox/` directory. Rewrite: `app_map_view.dart` facade. Update: `order_tracking_screen.dart`, `tracking_route_provider.dart`, `tracking_map_markers.dart`, `checkout_screen.dart`, `add_address_sheet.dart`. Delete: `app_map_marker.dart`, `app_map_route_point.dart` |
| 1 | both apps | New: `core/map/google/google_map_view.dart`, `google_directions_service.dart`, `google_route_service.dart`, `google_bootstrap.dart`. Both `pubspec.yaml`. Relocate `geolocator_location_service.dart` |
| 2 | both apps | Swap: `app_map_view.dart` facade, route providers, `main.dart`. Delete: `core/map/mapbox/` directories. Remove `mapbox_maps_flutter` from pubspec |
| 3 | backend | `maps.service.ts`, `configuration.ts`, `.env` |
| 4 | both apps + backend | AndroidManifest, build.gradle, AppDelegate, `.env` files, CI config |

## Existing code to reuse
- Rider app's `GeoPoint`, `MapMarker`, `RouteService`, `LocationService` abstractions — copy to customer app
- Both apps' Canvas-drawn marker bitmaps — `BitmapDescriptor.bytes()` accepts the same `Uint8List`
- `geolocator` package — completely vendor-neutral, no changes needed
- WebSocket location pipeline — uses raw lat/lng, no map SDK dependency
- Backend's Haversine + delivery zone utils — pure math, no vendor dependency
