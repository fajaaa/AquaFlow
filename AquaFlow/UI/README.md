# AquaFlow UI (`aquaflow_desktop`)

Flutter client for the AquaFlow backend (`AquaFlow.WebAPI`). Runs on Windows /
macOS / Linux desktop, Android, iOS and web from a single codebase. This
document covers the auth flow and the **local dev network settings** you need to
talk to the HTTP backend.

## Prerequisites

- Flutter SDK (Dart `^3.12`).
- The backend running locally. See the root `README.md`: start SQL Server
  (`docker compose up -d`), set the JWT/connection env vars, then
  `dotnet run --project ...AquaFlow.WebAPI... --launch-profile http`
  (listens on `http://localhost:5161` and on the PC LAN IP for physical
  phone/tablet testing).

## Run

```powershell
cd AquaFlow/UI
flutter pub get
flutter run                 # pick a device, or:
flutter run -d windows
flutter run -d chrome
```

> **Windows desktop:** building with native plugins (this app uses
> `flutter_secure_storage`) requires symlink support. If `flutter run -d windows`
> asks for it, enable **Developer Mode** (`start ms-settings:developers`).

### Seed login credentials (local demo DB)

`admin@aquaflow.ba`, `collector@aquaflow.ba`, `customer@aquaflow.ba` - all with
password `AquaFlow123!`.

## How auth works

- `lib/config/api_config.dart` - single source of the backend base URL. **Never
  hardcode the host anywhere else**; always read `ApiConfig.baseUrl`.
- `lib/services/auth_api_service.dart` - calls `POST /Access/login` and
  `POST /Access/refresh`, mapping errors to a friendly `AuthException`.
- `lib/services/token_storage.dart` - stores the access/refresh tokens in the
  platform secure store via `flutter_secure_storage`.
- `lib/providers/auth_provider.dart` - the auth state (`provider`). On startup it
  restores a session from stored tokens (using the access token while valid,
  otherwise silently refreshing).
- `lib/models/auth_session.dart` - decodes the JWT (`jwt_decoder`) into the
  signed-in user (`Email`, `UserRole`, `IsActive`, `Permission` claims).
- `lib/main.dart` - an `_AuthGate` shows the login or home screen based on state.

## Host selection per platform

`ApiConfig.baseUrl` picks the host automatically (port `5161`):

| Target                                    | Host used             |
| ----------------------------------------- | --------------------- |
| Android emulator                          | `10.0.2.2`            |
| iOS simulator, Windows, macOS, Linux, web | `localhost`           |
| Physical phone                            | set `lanHostOverride` |

### Physical phone

A real device cannot reach your PC via `localhost`/`10.0.2.2`. Set
`ApiConfig.lanHostOverride` to your PC's LAN IP (e.g. `"192.168.1.20"`, find it
with `ipconfig`) and make sure the phone is on the same Wi-Fi and the backend is
reachable (bind it to `0.0.0.0` / allow it through the firewall).

## Local dev network settings (cleartext HTTP)

The backend serves plain **HTTP** in local dev, and mobile platforms block
cleartext traffic by default. These **DEV-ONLY** exceptions are already in place:

- **Android** - `android/app/src/debug/AndroidManifest.xml` sets
  `android:usesCleartextTraffic="true"` on `<application>`. It lives in the
  **debug** manifest, so release builds are unaffected.
- **iOS** - `ios/Runner/Info.plist` adds `NSAppTransportSecurity` >
  `NSAllowsLocalNetworking` (allows local/LAN cleartext without disabling ATS
  globally).

> ⚠️ **Production:** these are local development conveniences only. In production
> the backend must be served over **HTTPS**, and both exceptions must be removed
> (delete `usesCleartextTraffic` from the debug manifest / the
> `NSAppTransportSecurity` block from `Info.plist`) so the app rejects cleartext.

## Push notifications (Firebase Cloud Messaging)

Push is mobile-only (Android/iOS) - there is no admin desktop UI for it, so
`Firebase.initializeApp()` in `lib/main.dart` only runs when the platform is
neither web nor desktop (same check as `PlatformGate.isDesktop`). This section
covers the native config every developer must supply locally; none of it is
committed (see `.gitignore`).

### Android

1. In the [Firebase console](https://console.firebase.google.com/), add an Android
   app with package name `ba.aquaflow.aquaflow_desktop`, download
   **`google-services.json`**, and place it at `android/app/google-services.json`.
2. That's it - `android/settings.gradle.kts` and `android/app/build.gradle.kts`
   already apply the `com.google.gms.google-services` Gradle plugin, which reads
   this file at build time. Without the file, any `flutter build android` /
   `flutter run` targeting Android fails immediately with a clear
   "File google-services.json is missing" error.
3. `POST_NOTIFICATIONS` (required on Android 13+ to actually show a notification)
   is declared in `android/app/src/main/AndroidManifest.xml`; the runtime prompt
   itself is requested by `PushNotificationService.requestPermissionAndRegister()`
   (see below).

### iOS

1. In the Firebase console, add an iOS app with bundle ID
   `ba.aquaflow.aquaflowDesktop`, download **`GoogleService-Info.plist`**, and
   place it at `ios/Runner/GoogleService-Info.plist`. Also drag it into the
   `Runner` target in Xcode (Runner.xcworkspace) so it's copied into the app
   bundle - adding the file on disk alone is not enough.
2. In Xcode, select the `Runner` target > **Signing & Capabilities** > **+
   Capability** > **Push Notifications**. This can only be done from Xcode, not
   from code, and also requires an Apple Developer account with APNs enabled for
   the app's bundle ID.
3. `ios/Runner/AppDelegate.swift` calls `FirebaseApp.configure()` before the
   Flutter engine starts (needed so FirebaseMessaging's APNs wiring attaches
   early); `firebase_core`'s own `Firebase.initializeApp()` call from
   `main.dart` detects the already-configured app and is a no-op on iOS.
4. `firebase_core`/`firebase_messaging` ship CocoaPods podspecs only (no Swift
   Package Manager manifest yet), so this project - otherwise fully on SPM (see
   `ios/Flutter/ephemeral/Packages`) - needs `ios/Podfile` (the standard
   Flutter-generated template) to pull them in via CocoaPods alongside the SPM
   plugins. Run `flutter pub get` then, on macOS, `pod install` from `ios/`
   (or just `flutter build ios` / `flutter run`, which does this for you) before
   opening `Runner.xcworkspace`.

### Client wiring

Runtime permission requests, device-token registration/refresh, and
foreground/background/terminated message handling are all wired up client-side -
see `PushNotificationService`/`PushMessageHandler`/`AuthProvider` in
`lib/shared/services` and `lib/shared/providers`. Only the native config above
(the two developer-supplied files and the Xcode capability) still has to be
done by hand per machine.
