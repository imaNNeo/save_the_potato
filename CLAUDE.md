# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Save The Potato is a cross-platform casual game built with Flutter and the Flame game engine. It won Flame Jam 3 (theme: "Hot & Cold", constraint: "No Text"). Published on Google Play and the App Store.

- **Dart SDK:** >=3.2.3 <4.0.0
- **Platforms:** Android, iOS, Web, macOS, Linux, Windows
- **Package name:** `dev.app2pack.savethepotato`

## Build & Development Commands

```bash
# Run the app
flutter run

# Run all quality checks + tests (use this before pushing)
make sure

# Individual commands
make analyze        # flutter analyze
make checkFormat    # dart format -o none --set-exit-if-changed .
make format         # dart format .
make runTests       # flutter test

# Firebase setup (required for first-time setup)
make firebaseConfigs
```

**iOS development setup** requires `fastlane match development` with `FASTLANE_USER`, `ITC_TEAM_ID`, and `TEAM_ID` environment variables configured.

## Architecture

Clean Architecture with BLoC (Cubit) state management and GetIt for dependency injection.

### Layer Structure (`lib/`)

- **`domain/`** — Business logic layer: repository interfaces (`repository/`), data models (`models/`), and analytics contracts. This is the innermost layer with no framework dependencies.
- **`data/`** — Data layer: repository implementations, local data sources (`sources/local/` using SharedPreferences/SecureStorage), and remote data sources (`sources/remote/` using Firebase Cloud Functions via `FirebaseFunctionsWrapper`).
- **`presentation/`** — UI layer: Cubits (`cubit/`), pages (`pages/`), Flame game components (`components/`), widgets, dialogs, effects, and helpers (including `AudioHelper` using flutter_soloud).

### Key Wiring

- **`main.dart`** — Firebase initialization (Android/iOS only), `setupServiceLocator()` call, `MultiBlocProvider` setup with all 6 Cubits, dark theme with custom "Cookies" font.
- **`service_locator.dart`** — GetIt registration of all dependencies: helpers, data sources (local + remote), and repositories. Uses `SecureKeyValueStorage` on mobile, `SharedPrefKeyValueStorage` on other platforms.

### Cubits (State Management)

| Cubit | Responsibility |
|-------|---------------|
| `GameCubit` | Core game logic, audio, scores, config |
| `ConfigsCubit` | App configuration from remote |
| `SettingsCubit` | User preferences, audio settings |
| `ScoresCubit` | Leaderboard and score tracking |
| `AuthCubit` | Firebase authentication |
| `SplashCubit` | App initialization flow |

### Firebase Integration

- **Auth, Crashlytics, Analytics, Cloud Functions** — Active on Android/iOS only
- Crashlytics captures fatal errors in release mode
- Backend logic runs through Cloud Functions (see `functions/` directory)
- Config generated via `flutterfire configure --project=save-the-potato`

## Release Process

See `docs/RELEASE_GUIDE.md`. Key steps: create `release/x.y.z` branch, update version in `pubspec.yaml`, update `CHANGELOG.md` and `assets/texts/release_notes.json`, tag and publish GitHub Release to trigger CI build.
