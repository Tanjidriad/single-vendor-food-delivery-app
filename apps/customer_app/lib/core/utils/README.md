# Utils (CWT adapted — no GetX / Firebase)

All helpers work with **Riverpod** and **`BuildContext`**. Legacy `T*` names are typedef aliases.

| File | Class | Notes |
|------|--------|------|
| `constants/sizes.dart` | `AppSizes` | Spacing tokens |
| `constants/text_strings.dart` | `TTexts` | Copy strings (customize per screen) |
| `validators/validation.dart` | `AppValidator` | Form validators |
| `formatters/formatter.dart` | `AppFormatter` | BDT currency, dates |
| `popups/loaders.dart` | `AppLoaders` | Pass `BuildContext` |
| `popups/full_screen_loader.dart` | `AppFullScreenLoader` | Blocking dialog |
| `device/device_utility.dart` | `DeviceUtils` | Pass `BuildContext` |
| `helpers/network_manager.dart` | `NetworkConnectivity` | Use via `NetworkListener` in `app.dart` |
| `local_storage/storage_utility.dart` | `LocalStorage` | `shared_preferences` |
| `logging/logger.dart` | `AppLogger` | Dev logging |

**Removed:** Firebase helpers, GetX, duplicate theme/colors, `http_client`, `pricing_calculator`.

**Theme/colors:** use `lib/core/theme/app_colors.dart` and `app_theme.dart` (Option A Ember).
