# Copilot Instructions for AI Agents

## Project Overview
- **pockethome** is a cross-platform Flutter app (Android, iOS, Web, Windows, macOS, Linux) for smart home control and user customization.
- Main code is in `lib/`:
  - `main.dart`: App entry point, navigation setup.
  - `models/`: Data models (e.g., `user_settings.dart`).
  - `screens/`: UI screens (e.g., `main_screen.dart`, `user_id_input_screen.dart`).
  - `widgets/`: Reusable UI components (e.g., `brightness_control.dart`, `temperature_control.dart`).

## Architecture & Data Flow
- Follows standard Flutter widget tree and navigation patterns.
- User settings and controls are managed via models and passed between screens/widgets.
- Integrates with Firebase (`firebase_core`, `firebase_database`) for backend data storage and sync.
- Uses `shared_preferences` for local persistent storage.

## Developer Workflows
- **Build/Run:**
  - Use `flutter run` for development.
  - Platform-specific builds: `flutter build apk`, `flutter build ios`, etc.
- **Dependencies:**
  - Add packages with `flutter pub add <package>`.
  - After adding dependencies, always run `flutter pub get`.
- **Testing:**
  - No custom test setup detected; use standard Flutter/Dart test conventions.
- **Debugging:**
  - Use Flutter DevTools and platform-specific IDE debugging.

## Conventions & Patterns
- UI logic is separated into screens and widgets for modularity.
- Data models are in `lib/models/` and should be used for any persistent or shared state.
- All cross-component communication should use Flutter's state management and navigation.
- Firebase and shared_preferences are the only external state/storage integrations.
- No custom rules or agent instructions found in the codebase; follow standard Flutter/Dart best practices unless otherwise specified in this file.

## Integration Points
- **Firebase:**
  - Initialize in `main.dart` or a dedicated service file.
  - Use `firebase_database` for real-time data sync.
- **Shared Preferences:**
  - Store simple user settings locally.

## Key Files & Directories
- `lib/main.dart`: App entry, Firebase init, navigation.
- `lib/models/user_settings.dart`: User settings model.
- `lib/screens/`: Main UI screens.
- `lib/widgets/`: UI components for controls and dialogs.
- `pubspec.yaml`: Dependency management.

## Example Patterns
- Widget composition: See `lib/widgets/brightness_control.dart` for custom control implementation.
- Screen navigation: See `lib/screens/main_screen.dart` for navigation logic.
- Model usage: See `lib/models/user_settings.dart` for state management.

---
If any conventions or workflows are unclear, ask the user for clarification or examples from their codebase.
