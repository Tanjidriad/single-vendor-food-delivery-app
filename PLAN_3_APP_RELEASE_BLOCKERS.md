# Plan 3: App release blockers (all 3 Flutter apps)

> Priority: P0 — blocks Play Store / App Store submission
> Estimated effort: 2-3 days

---

## Objective

Fix every issue that prevents the three Flutter apps (customer, rider, kitchen) from being submitted to the Play Store and functioning correctly in production.

---

## Shared tasks (all 3 apps)

### 3.1 Set up production signing for all apps

**Problem:** All three apps use `signingConfigs.getByName("debug")` for release builds.

**Files:**
- `apps/customer_app/android/app/build.gradle.kts`
- `apps/rider_app/android/app/build.gradle.kts`
- `apps/kitchen_app/android/app/build.gradle.kts`

**Actions per app:**
1. Generate a production keystore: `keytool -genkey -v -keystore release-key.jks -keyalg RSA -keysize 2048 -validity 10000`
2. Create `android/key.properties` (gitignored):
   ```
   storePassword=<password>
   keyPassword=<password>
   keyAlias=release
   storeFile=../release-key.jks
   ```
3. Update `build.gradle.kts` to load from `key.properties` for release
4. Add `key.properties` and `*.jks` to `.gitignore`

---

### 3.2 Set production bundle IDs

**Problem:** Apps use placeholder IDs (`com.example.rider_app`, `com.demokitchen.*`).

**Actions:**
- customer_app: Change `com.demokitchen.fooddelivery.customer_app` to production ID
- rider_app: Change `com.example.rider_app` to production ID
- kitchen_app: Verify `com.fooddelivery.kitchen_app` is the intended production ID

**Files:** `build.gradle.kts` (`applicationId`) + iOS `Info.plist` / Xcode project for each app.

---

### 3.3 Enable ProGuard / R8 for all apps

**Files:** All three `build.gradle.kts`

**Action:**
```kotlin
buildTypes {
    release {
        isMinifyEnabled = true
        isShrinkResources = true
        proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        signingConfig = signingConfigs.getByName("release")
    }
}
```

Create `proguard-rules.pro` per app with Flutter-standard rules.

---

### 3.4 Add crash reporting to all apps

**Problem:** `FlutterError.onError` and `PlatformDispatcher.instance.onError` only `debugPrint` in release.

**Actions per app:**
1. Add `sentry_flutter` (or `firebase_crashlytics`) to `pubspec.yaml`
2. Initialize in `app_bootstrap.dart`:
```dart
await SentryFlutter.init(
  (options) {
    options.dsn = const String.fromEnvironment('SENTRY_DSN');
    options.tracesSampleRate = 0.2;
  },
  appRunner: () => runApp(const ProviderScope(child: App())),
);
```
3. Route `FlutterError.onError` and `PlatformDispatcher.instance.onError` to Sentry

---

### 3.5 Remove `dev_api_host.txt` from production assets

**Problem:** All 3 apps bundle `assets/dev_api_host.txt` (containing LAN IPs) into the release APK.

**Actions:**
- Remove `dev_api_host.txt` from `pubspec.yaml` assets section
- Inject production API URL via `--dart-define=API_BASE_URL=https://api.yourapp.com` at build time
- Update `ApiHostResolver` to read `const String.fromEnvironment('API_BASE_URL')` as the primary source, falling back to asset file only in `kDebugMode`

---

### 3.6 Fix socket re-authentication after token refresh (all 3 apps)

**Problem:** When the 401 interceptor refreshes the access token, the socket continues using the old token.

**Files:**
- `apps/customer_app/lib/core/realtime/socket_service.dart`
- `apps/rider_app/lib/core/websockets/socket_service.dart`
- `apps/kitchen_app/lib/features/kds/presentation/providers/kds_provider.dart`

**Action:** After a successful token refresh in the Dio interceptor, disconnect and reconnect the socket with the new token. Either:
- Emit a token-refresh event that the socket service listens to
- Directly call `socketService.reconnectWithToken(newToken)`

---

## customer_app specific

### 3.7 Remove sandbox bKash UI

**File:** `apps/customer_app/lib/features/checkout/presentation/screens/bkash_payment_screen.dart`

**Actions:**
- Delete `_SandboxHelpBanner` widget entirely
- Remove the "Sandbox help" `IconButton` from the AppBar
- Remove the bottom bar with hardcoded wallet/PIN/OTP text
- Remove the "Done" button that bypasses the payment flow
- Change `subtitle: 'Pay now with bKash (sandbox test)'` to `'Pay now with bKash'` in checkout

---

### 3.8 Add iOS permission descriptions (customer_app)

**File:** `apps/customer_app/ios/Runner/Info.plist`

**Add:**
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We use your location to find your delivery address and track your order.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Access to your photo library lets you set a profile picture.</string>
<key>NSCameraUsageDescription</key>
<string>Camera access lets you take a profile photo.</string>
```

---

### 3.9 Fix socket room rejoin on reconnect (customer_app)

**File:** `apps/customer_app/lib/features/orders/presentation/providers/order_tracking_provider.dart`

**Action:** Add an `onReconnect` handler that re-joins the order room:
```dart
socket.onReconnect((_) {
  socket.joinOrder(orderId);
});
```

---

## rider_app specific

### 3.10 Replace simulated camera with real ImagePicker

**File:** `apps/rider_app/lib/features/orders/presentation/screens/active_delivery_screen.dart` — lines 498-527

**Action:** Replace `_showSimulatedCamera()` with:
```dart
final picker = ImagePicker();
final photo = await picker.pickImage(source: ImageSource.camera, maxWidth: 1024, imageQuality: 85);
if (photo != null) {
  // Upload to backend/Cloudinary and get the URL
  final url = await ref.read(uploadsRepositoryProvider).uploadImage(File(photo.path));
  setState(() => _dropoffPhotoUrl = url);
}
```

---

### 3.11 Gate `devCode` OTP behind `kDebugMode`

**Files:**
- `apps/rider_app/lib/features/auth/presentation/screens/forgot_password_screen.dart` — line 46
- `apps/rider_app/lib/features/onboarding/presentation/screens/onboarding_screen.dart` — line 376

**Action:** Wrap devCode display:
```dart
if (kDebugMode && devCode != null) {
  // show dev code snackbar
}
```

---

### 3.12 Add background location permission (rider_app)

**File:** `apps/rider_app/android/app/src/main/AndroidManifest.xml`

**Add:**
```xml
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />
```

**File:** `apps/rider_app/ios/Runner/Info.plist`

**Add:**
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to assign you nearby delivery orders.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Background location lets us track your delivery progress even when the app is minimized.</string>
<key>UIBackgroundModes</key>
<array><string>location</string></array>
```

---

### 3.13 Stop bundling `.env` as APK asset (rider_app)

**File:** `apps/rider_app/pubspec.yaml`

**Action:** Remove `.env` from the `assets:` list. Inject Mapbox token via `--dart-define=MAPBOX_TOKEN=pk.xxx` at build time. Update code to read `const String.fromEnvironment('MAPBOX_TOKEN')`.

---

## kitchen_app specific

### 3.14 Add `FLAG_KEEP_SCREEN_ON`

**File:** `apps/kitchen_app/android/app/src/main/kotlin/.../MainActivity.kt`

**Action:**
```kotlin
import android.view.WindowManager

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }
}
```

---

### 3.15 Move closing PIN to secure storage

**File:** `apps/kitchen_app/lib/core/services/kitchen_preferences.dart`

**Action:** Replace `SharedPreferences` read/write for `kitchen_closing_pin` with `FlutterSecureStorage`.

---

### 3.16 Gate all bare `print()` calls behind `kDebugMode`

**File:** `apps/kitchen_app/lib/features/kds/presentation/providers/kds_provider.dart`

**Action:** Find all 13+ `print(...)` calls and wrap in `if (kDebugMode)`, or replace with a logger that is no-op in release.

---

## Firebase (shared project — Android)

- [x] Canonical multi-app config at `infra/firebase/google-services.json`
- [x] Setup script: `scripts/firebase/setup-android-fcm.ps1` (register + sync all apps)
- [x] Backend FCM env helper: `scripts/firebase/configure-fcm-backend.ps1`
- [x] Android notification channel + `POST_NOTIFICATIONS` (all 3 apps)
- [x] ProGuard rules for Firebase (all 3 apps)
- [x] **You must run** `setup-android-fcm.ps1` logged in as owner of `wasabi-delivery-e7bf2` to register kitchen + customer apps
- [ ] **You must run** `configure-fcm-backend.ps1` with service-account JSON

## Implementation status

- [x] 3.1 Production signing configs (all 3 apps) — key.properties + release signingConfig
- [ ] 3.2 Bundle IDs — rider changed to com.fooddelivery.rider_app; customer still com.demokitchen (needs your production ID)
- [x] 3.3 ProGuard / R8 enabled (all 3 apps) — proguard-rules.pro created
- [~] 3.4 Crash reporting — rider_app: `sentry_flutter` ^9.0.0 wired in `main.dart`,
      active only when `--dart-define=SENTRY_DSN=...` is provided (no-ops otherwise so
      debug/unconfigured builds stay clean). Root `android/build.gradle.kts` raises the
      Kotlin language/api floor to 1.8 (Sentry's Android module requested 1.6, rejected
      by the Kotlin 2.2.20 compiler). **You must** create a Sentry project, get the DSN,
      and pass it at build time. customer_app + kitchen_app still pending.
- [x] 3.5 dev_api_host.txt gated behind kDebugMode in all resolvers, removed from pubspec assets
- [x] 3.6 Socket re-auth after token refresh (all 3 apps)
- [x] 3.7 Sandbox bKash UI fully removed
- [x] 3.8 iOS permission descriptions (customer_app)
- [x] 3.9 Socket room rejoin on reconnect (customer_app)
- [x] 3.10 Real ImagePicker AND real upload: POD photo now uploads via
      `UploadsRepository.uploadDeliveryProof` → backend `/uploads/image/delivery-proof`
      (RIDER-scoped) → Cloudinary URL. Previously the local file path was sent as
      `dropoffPhotoUrl`, which the backend could not use. kDebugMode fallback kept.
- [x] 3.11 devCode gated behind kDebugMode (forgot_password + onboarding)
- [x] 3.12 Background location now functional, not just permissioned:
      `GeolocatorLocationService` uses an Android foreground-service notification
      (`ForegroundNotificationConfig`) and iOS `allowBackgroundLocationUpdates`, and
      `HomeShell` keeps the socket alive in the background while an order is active.
      Permissions/Info.plist were already present.
- [x] 3.13 .env and dev_api_host.txt removed from pubspec assets, dart-define fallback added
- [x] 3.14 FLAG_KEEP_SCREEN_ON added (kitchen_app MainActivity)
- [x] 3.15 Closing PIN migrated to FlutterSecureStorage (auto-migrates from SharedPreferences)
- [x] 3.16 All bare print() calls gated behind kDebugMode (kitchen_app kds_provider)

## Verification checklist

- [ ] `flutter build apk --release` succeeds with production signing for all 3 apps
- [ ] `bundletool dump manifest` shows correct `applicationId` for each
- [ ] `apkanalyzer` confirms no `dev_api_host.txt`, no `.env` in release APK
- [ ] bKash screen shows no sandbox UI or "Done" button
- [ ] Rider app opens real camera for proof of delivery
- [ ] Rider app does not show dev OTP code in release build
- [ ] Kitchen display stays on after 10 minutes of inactivity
- [ ] All apps report a test crash to Sentry/Crashlytics dashboard
- [ ] Socket reconnects with fresh token after a forced 401 refresh
- [ ] Customer app re-joins tracking room after socket reconnect
- [ ] `adb logcat` shows no socket URLs or internal state from kitchen app in release
