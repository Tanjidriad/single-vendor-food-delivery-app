# Customer app — Clean Architecture

## Layer rules

```
presentation  →  domain  ←  data
     │              │
     └──────────────┘  (presentation never imports data directly)
```

| Layer | Responsibility | Depends on |
|-------|----------------|------------|
| **domain** | Entities, repository contracts, use cases | Nothing (pure Dart) |
| **data** | API models, remote/local sources, repository implementations | domain |
| **presentation** | Screens, widgets, Riverpod providers | domain |

**core/** is shared infrastructure: theme, router, Dio, config, utils (your pasted helpers).

## Folder layout

```
lib/
  main.dart
  app.dart
  core/
    config/
    constants/
    errors/
    network/
    router/
    theme/          # Option A — Warm Ember
    utils/          # ← paste CWT utils here (adapted)
  features/
    <feature>/
      domain/
        entities/
        repositories/
        usecases/
      data/
        datasources/
        models/
        repositories/
      presentation/
        providers/
        screens/
        widgets/
```

## Adding a feature (example: `menu`)

1. `domain/entities/menu_item_entity.dart`
2. `domain/repositories/menu_repository.dart`
3. `domain/usecases/get_menu_usecase.dart`
4. `data/models/menu_item_model.dart`
5. `data/datasources/menu_remote_datasource.dart`
6. `data/repositories/menu_repository_impl.dart`
7. `presentation/providers/menu_providers.dart`
8. `presentation/screens/...`

## State management

- **Riverpod** for DI and UI state
- **go_router** for navigation
- **Dio** + `authTokenProvider` for authenticated API calls
- **flutter_secure_storage** for tokens

## API base URL

| Platform | Default (`AppConfig`) |
|----------|------------------------|
| Android emulator | `http://10.0.2.2:3000/api/v1` |
| iOS simulator | use `--dart-define=API_BASE_URL=http://localhost:3000/api/v1` |
| Physical device | your PC LAN IP, e.g. `http://192.168.1.5:3000/api/v1` |

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.5:3000/api/v1
```
