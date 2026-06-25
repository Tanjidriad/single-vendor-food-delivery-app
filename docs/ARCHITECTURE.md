# Mobile App Architecture & Conventions

This document is the single source of truth for **how a feature is built** in the
Flutter apps (`apps/customer_app`, `apps/rider_app`, and — as they adopt it —
`apps/kitchen_app`, `apps/admin_app`). New code and refactors must follow it.
When in doubt, copy the reference feature: `apps/customer_app/lib/features/auth`.

> Status: adopted as the target during the production-readiness refactor
> (see the phased plan). Existing features are being migrated toward it
> feature-by-feature; do not assume every folder already complies.

---

## 1. Stack

| Concern            | Choice                                  |
| ------------------ | --------------------------------------- |
| State management   | **Riverpod 3** (`Notifier` / `AsyncNotifier`) |
| Navigation         | **go_router** (centralized in `core/router`) |
| Networking         | **dio** (one configured client per app in `core/network`) |
| Value equality     | **equatable** |
| Secure storage     | `flutter_secure_storage` behind a `TokenStorage` seam |

`StateNotifier` and `ChangeNotifier` are **legacy**. Do not introduce new ones;
migrate them to `Notifier`/`AsyncNotifier` when you touch them.

---

## 2. Feature folder template

Every feature lives under `lib/features/<feature>/` and follows this shape:

```
features/<feature>/
  data/
    models/                 <thing>_model.dart    # typed, fromJson/toJson, Equatable
    <feature>_repository.dart                      # returns models, maps errors
  presentation/
    providers/              <feature>_providers.dart   # Notifier / AsyncNotifier
    screens/                <feature>_screen.dart       # thin: watch + render + dispatch
    widgets/                ...                          # sub-widgets, each < ~300 lines
  domain/                    # OPTIONAL — only for genuinely complex features
    entities/                # (checkout, active-delivery, order-tracking).
    usecases/                # Add when orchestration outgrows the repository.
```

**Layering is pragmatic, not dogmatic.** The default is `data + presentation`.
Add a `domain/` layer (entities + use-cases) **only** when a feature has real
orchestration logic that would otherwise bloat a repository or a notifier.
Do not create empty `domain/` folders "for symmetry."

---

## 3. Rules of the standard

### 3.1 Repositories
- **Never return `dynamic` / `Map<String, dynamic>` / `List<dynamic>` across a
  feature boundary.** Map JSON to typed models in the repository.
- **Never force-unwrap** `res.data!`. Guard nulls and throw a typed `Failure`.
- Convert `DioException` → typed `Failure` via `core/errors/map_dio_exception.dart`.

```dart
Future<OrderModel> getOrder(String id) async {
  try {
    final res = await _dio.get<Map<String, dynamic>>(ApiEndpoints.order(id));
    final data = res.data;
    if (data == null) throw const ServerFailure('Empty order response');
    return OrderModel.fromJson(data);
  } on DioException catch (e) {
    throw mapDioException(e);
  }
}
```

### 3.2 Providers (state)
- Use `AsyncNotifier<T>` for async-loaded state, `Notifier<T>` for synchronous
  state. Expose `AsyncValue<T>` to the UI.
- One provider file per feature area; **split when it exceeds ~250 lines**
  (e.g. don't combine session + token + profile in one notifier).
- Side effects (push registration, socket connect, cache warmup) belong inside a
  notifier method — **not** scattered across widgets or chained in `build()`.

### 3.3 Screens & widgets
- Screens **watch a provider and render**. No API calls, no JSON parsing, no
  business math (totals, fees, distances) inside a widget.
- Render async state with `.when(data:, loading:, error:)`.
- **No widget over ~300 lines.** Extract sub-widgets into `presentation/widgets/`.
- Prefer `const` constructors; use `ListView.builder` for unbounded lists.

### 3.4 Dependency injection
- All dependencies are provided via Riverpod providers (`ref.watch` / `ref.read`).
- Wrap singletons (secure storage, socket, dio) behind a provider so tests can
  override them — never instantiate `FlutterSecureStorage()` / `Dio()` inline
  inside a repository or notifier.

---

## 4. Naming conventions

| Thing                | Rule                                              |
| -------------------- | ------------------------------------------------- |
| Provider variables   | `<name>Provider` (e.g. `ordersRepositoryProvider`) |
| Model classes        | `<Thing>Model` in `data/models/`                  |
| Repository classes   | `<Feature>Repository`                             |
| Secure-storage keys   | top-level `const _kAccessToken = 'access_token';` (one place per app) |
| Socket base URL      | **`socketBaseUrl`** everywhere — `apps/rider_app`'s `AppConfig.socketUrl` is being renamed to match `customer_app` |
| Files                | `snake_case.dart`, one public type per file where practical |

Resolve drift toward the **customer_app** spelling (`socketBaseUrl`,
`apiBaseUrl`) since it already parallels `ApiHostResolver`.

---

## 5. Error handling

- Domain errors are modeled by the sealed `Failure` hierarchy in
  `core/errors/failures.dart` (`ServerFailure`, `NetworkFailure`,
  `CacheFailure`, `AuthFailure`).
- Repositories throw `Failure` (mapped from `DioException`). Notifiers catch and
  place the message into `AsyncValue.error`. Screens render it via `.when(error:)`.
- Do **not** surface raw `e.toString()` / `DioException` to the UI.

---

## 6. Realtime

- One canonical socket service per app modeled on `apps/rider_app`'s
  implementation: `StreamController` per event type, exponential-backoff
  reconnect, lifecycle-aware (reconnect on resume), full teardown in `dispose()`.
- Every `StreamSubscription` and `Timer` must be cancelled in `ref.onDispose`.
  The `cancel_subscriptions` / `close_sinks` lints guard this.

---

## 7. Testing conventions

- **Repositories:** unit-test JSON→model mapping and `DioException`→`Failure`
  using `http_mock_adapter`.
- **Notifiers:** test with a `ProviderContainer` and overridden repository /
  `TokenStorage` fakes.
- **Widgets:** test decomposed sub-widgets; seed providers with fakes (see the
  `FakeAuthNotifier` pattern in `apps/admin_app/test`).
- Every app must pass `flutter analyze` (zero issues) and `flutter test` — both
  enforced in CI (`.github/workflows/*-app-ci.yml`).

---

## 8. Lint / analysis

Shared rules live in the **repo-root `analysis_options.yaml`**, included by each
app's `analysis_options.yaml`. Correctness lints are enabled
(`unawaited_futures`, `cancel_subscriptions`, `close_sinks`, `avoid_print`, …).
`strict-casts` / `strict-raw-types` are deferred until the typed-data-layer
migration is complete, then will be turned on to lock it in.

---

## 9. Shared package (planned, not yet executed)

Today each app copies its `core/` (network, theme, realtime, errors) — ~70–80%
duplicated with version drift. The target is a **Melos workspace**:

```
packages/
  core_network/    # unified dio + token refresh + TokenStorage
  core_realtime/   # the canonical socket service
  core_errors/     # Failure + mapDioException
  core_ui/         # neutral theme scales + shared widgets (brand colors stay per-app)
```

The refactor deliberately **converges the four implementations first** (typed
data, unified Riverpod, hardened socket) so that extraction later is a *move*,
not a rewrite. Until then, when you fix a bug in one app's `core/`, check whether
the same bug exists in the others.
