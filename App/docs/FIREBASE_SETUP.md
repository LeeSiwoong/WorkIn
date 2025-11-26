# Firebase setup (Android-first)

This project writes settings to Firebase Realtime Database at `users/{userId}`.
Follow these steps to connect an existing Firebase project.

## 1) Android configuration
- In Firebase Console, open your project and the Android app you registered for it.
  - If you don't have an Android app yet, add one using your package name (the app currently uses `com.example.pockethome` in `android/app/build.gradle.kts`).
- Download `google-services.json` for the Android app.
- Place it at: `android/app/google-services.json`.
- Ensure the package name in the file matches `applicationId` in `android/app/build.gradle.kts`.

Gradle is already configured to apply the Google Services plugin.

## 2) iOS (optional)
- Download `GoogleService-Info.plist` and place it at `ios/Runner/GoogleService-Info.plist`.

## 3) Web/Windows (optional)
- Prefer generating `lib/firebase_options.dart` with FlutterFire CLI:
  - Install Firebase CLI, then run: `flutterfire configure --project <PROJECT_ID> --platforms=android,ios,web,windows`
  - Update `main.dart` to call `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`.

## 4) Database rules (development)
Use permissive rules for quick demos only:
```
{
  "rules": {
    ".read": true,
    ".write": true
  }
}
```
For production, restrict to authenticated users and per-user paths.

## 5) Android toolchain checklist
- Install Android SDK Command-line tools via Android Studio > SDK Manager.
- Accept licenses: `flutter doctor --android-licenses`.
- On Windows, enable Developer Mode for symlink support.
- Prefer ASCII path for Flutter SDK (e.g., `C:\\src\\flutter`). Update `android/local.properties` `flutter.sdk` accordingly.

## 6) Run
```
flutter clean
flutter pub get
flutter devices
flutter run -d <emulator-id>
```

If build fails, run `flutter doctor -v` and fix reported items.
