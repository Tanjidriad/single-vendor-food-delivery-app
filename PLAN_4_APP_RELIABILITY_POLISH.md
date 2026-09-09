# Plan 4: App reliability, offline handling & polish

> Priority: P2 — improves user experience and operational resilience
> Estimated effort: 3-5 days

---

## Objective

Make all three apps resilient to network issues, remove leftover test/hardcoded data, add missing validation, and polish for a production-quality experience.

---

## Offline & resilience (all apps)

### 4.1 Add connectivity monitoring (all 3 apps)

**Problem:** None of the apps detect network state changes. Failed API calls are indistinguishable from server errors.

**Actions per app:**
1. Add `connectivity_plus` to `pubspec.yaml`
2. Create a `connectivityProvider` (Riverpod `StreamProvider`) that emits online/offline state
3. Show a persistent offline banner at the top of the screen when offline
4. Suppress auto-polling when offline to avoid flooding failed requests

---

### 4.2 Add offline retry queue for status updates (rider + kitchen)

**Problem:** If a rider taps "Picked Up" or kitchen taps "Mark Ready" during a network blip, the update is silently lost.

**Actions:**
1. Create an `OfflineActionQueue` that persists pending actions to `SharedPreferences`
2. On network failure for status update calls, enqueue the action instead of showing an error
3. On connectivity restored, drain the queue and replay actions in order
4. Show a "Pending sync" indicator on queued items

**Files:**
- `apps/rider_app/lib/features/orders/` — new `offline_queue.dart`
- `apps/kitchen_app/lib/features/kds/` — new `offline_queue.dart`

---

### 4.3 Fix Mapbox timeout (customer + rider)

**Problem:** `MapboxDirectionsService` creates a bare `Dio()` with no timeout.

**Files:**
- `apps/customer_app/lib/core/map/mapbox_directions_service.dart`
- `apps/rider_app/lib/core/map/mapbox_directions_service.dart`

**Action:**
```dart
MapboxDirectionsService({Dio? dio})
    : _dio = dio ?? Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));
```

---

## Validation fixes

### 4.4 Add login validation (rider_app)

**Problem:** Login screen sends empty credentials directly to the API with no client-side check.

**File:** `apps/rider_app/lib/features/auth/presentation/screens/login_screen.dart`

**Action:** Add validation before API call:
```dart
if (phone.isEmpty) { showError('Phone number is required'); return; }
if (password.isEmpty) { showError('Password is required'); return; }
```

---

### 4.5 Add phone validator to Edit Profile (customer_app)

**Problem:** Phone field in Edit Profile has no validator — any string accepted.

**File:** `apps/customer_app/lib/features/profile/presentation/screens/edit_profile_screen.dart`

**Action:** Add `validator: AppValidator.validatePhoneNumber` to the phone `AppTextField`.

---

### 4.6 Add max-length to delivery instructions (customer_app)

**File:** `apps/customer_app/lib/features/checkout/presentation/screens/checkout_screen.dart`

**Action:** Add `maxLength: 500` and `maxLines: 3` to the delivery instructions `TextField`.

---

### 4.7 Add digit-only filter to OTP inputs (rider_app)

**File:** `apps/rider_app/lib/features/orders/presentation/screens/active_delivery_screen.dart`

**Action:** Add `inputFormatters: [FilteringTextInputFormatter.digitsOnly]` to the OTP PIN field.

---

## Hardcoded data removal

### 4.8 Replace hardcoded restaurant name (customer_app)

**Problem:** "Golpo - Mirpur 06" hardcoded in checkout.

**File:** `apps/customer_app/lib/features/checkout/presentation/screens/checkout_screen.dart` — line 268

**Action:** Fetch restaurant name from `restaurantProvider` or `configProvider` and display dynamically.

---

### 4.9 Replace placeholder privacy policy & terms (customer_app)

**File:** `apps/customer_app/lib/features/auth/presentation/screens/register_screen.dart`

**Action:** Replace inline placeholder text with either:
- Links to hosted legal pages: `launchUrl(Uri.parse('https://yourapp.com/privacy'))`
- Or properly drafted inline text from the business owner

---

### 4.10 Remove hardcoded mock menu items (kitchen_app)

**File:** `apps/kitchen_app/lib/features/kds/presentation/widgets/menu_availability_drawer.dart`

**Action:** Replace the 6 hardcoded fake menu items with a real API call to fetch menu items, or remove the drawer entirely if the feature is not ready.

---

### 4.11 Replace hardcoded VAT with order data (kitchen_app)

**File:** `apps/kitchen_app/lib/features/kds/presentation/screens/order_detail_screen.dart` — line 138

**Problem:** `final vat = subtotal * 0.15; // mock VAT for UI`

**Action:** Read VAT/tax from the order object returned by the API. If the backend doesn't include tax breakdown, add it to the order response first.

---

### 4.12 Remove "Remember me" no-op checkbox (rider_app)

**Problem:** Checkbox exists on login and signup but its value is never used — tokens always persist.

**Files:**
- `apps/rider_app/lib/features/auth/presentation/screens/login_screen.dart`
- `apps/rider_app/lib/features/onboarding/presentation/screens/onboarding_screen.dart`

**Action:** Either:
- Remove the checkbox entirely (simplest — tokens always persist is fine for a rider app)
- Or implement real session-only mode (don't write to secure storage when unchecked)

---

### 4.13 Replace Picsum placeholder images (customer + rider)

**Problem:** `picsum.photos` and `unsplash` URLs used as placeholders throughout.

**Files:**
- `apps/customer_app/lib/core/utils/placeholder_images.dart`
- Sample widgets in customer_app
- `apps/rider_app/lib/features/orders/presentation/screens/active_delivery_screen.dart` — line 516

**Action:** Replace with local bundled placeholder assets (`assets/images/food_placeholder.png`) to avoid dependency on external CDNs.

---

## UX polish

### 4.14 Add delete confirmation for addresses (customer_app)

**File:** `apps/customer_app/lib/features/profile/presentation/screens/addresses_screen.dart`

**Action:** Wrap the delete call in a confirmation dialog:
```dart
final confirmed = await showDialog<bool>(
  context: context,
  builder: (_) => AlertDialog(
    title: const Text('Delete address?'),
    content: const Text('This cannot be undone.'),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
    ],
  ),
);
if (confirmed == true) { /* delete */ }
```

---

### 4.15 Add socket error handler (customer_app)

**File:** `apps/customer_app/lib/core/realtime/socket_service.dart`

**Action:** Wire up `_socket?.onError((err) { ... })` to log the error and trigger a reconnect attempt.

---

### 4.16 Sanitize error messages shown to users (customer_app)

**Problem:** Raw exception strings shown in snackbars (e.g., checkout screen).

**File:** `apps/customer_app/lib/features/checkout/presentation/screens/checkout_screen.dart`

**Action:** Replace `Text('$e')` with user-friendly messages:
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Something went wrong. Please try again.')),
);
```

---

### 4.17 Add screen burn-in mitigation (kitchen_app)

**Problem:** Static column headers displayed 12+ hours/day on the same pixels.

**File:** `apps/kitchen_app/lib/features/kds/presentation/screens/kds_board_screen.dart`

**Action:** Add a subtle periodic pixel shift (every 5 minutes, offset the entire layout by 1-2 pixels in a random direction):
```dart
Timer.periodic(const Duration(minutes: 5), (_) {
  setState(() {
    _offsetX = Random().nextInt(3) - 1; // -1, 0, or 1
    _offsetY = Random().nextInt(3) - 1;
  });
});
```

Wrap the board in `Transform.translate(offset: Offset(_offsetX.toDouble(), _offsetY.toDouble()))`.

---

## Testing

### 4.18 Add integration tests for critical flows

**Priority flows to test:**
1. customer_app: Cart -> Checkout -> Order placed (mocked API)
2. rider_app: Accept assignment -> Navigate -> Mark picked up -> Mark delivered (mocked API)
3. kitchen_app: Receive order via socket -> Accept -> Mark preparing -> Mark ready (mocked API)

**Action:** Create `integration_test/` directory in each app with at least one golden-path test using `patrol` or `integration_test` package.

---

## Verification checklist

- [ ] Offline banner appears when airplane mode is toggled (all apps)
- [ ] Rider "Picked Up" action queued offline, syncs when connectivity returns
- [ ] Kitchen "Mark Ready" action queued offline, syncs when connectivity returns
- [ ] Login screen rejects empty phone/password with error message (rider)
- [ ] Delivery instructions capped at 500 chars (customer)
- [ ] No "Golpo - Mirpur 06" visible in checkout — restaurant name is dynamic
- [ ] Privacy policy links open real legal pages
- [ ] No Picsum/Unsplash URLs in any release APK (`strings app.apk | grep picsum` returns empty)
- [ ] Kitchen display shifts pixels every 5 minutes (observe over 15 min)
- [ ] Address delete shows confirmation dialog
- [ ] Error snackbars show friendly messages, not raw exceptions
- [ ] At least one integration test passes per app
