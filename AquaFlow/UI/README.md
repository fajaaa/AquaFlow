# AquaFlow UI

Three independent Flutter clients for the AquaFlow backend (`AquaFlow.WebAPI`), one per role. There is **no shared package** between them - each is a fully self-contained Flutter project with its own `pubspec.yaml` and its own copy of what used to be one combined app's shared code. A change to shared logic (auth, API config, theme, etc.) has to be applied by hand in all 3 - see `AGENTS.md` at the repo root ("UI (Flutter client)" section) for the full rationale and folder layout.

| Project | Role | Platforms | Package ID |
|---|---|---|---|
| `aquaflow_desktop` | Admin | Windows / macOS / Linux | (desktop app, no Android/iOS package ID) |
| `aquaflow_customer` | Customer | Android / iOS | `ba.aquaflow.aquaflow_customer` (Android) / `ba.aquaflow.aquaflowCustomer` (iOS) |
| `aquaflow_collector` | Collector | Android / iOS | `ba.aquaflow.aquaflow_collector` (Android) / `ba.aquaflow.aquaflowCollector` (iOS) |

## Prerequisites

- Flutter SDK (Dart `^3.12`).
- The backend running locally. See the root `README.md`: start SQL Server (`docker compose up -d`), set the JWT/connection env vars, then `dotnet run --project ...AquaFlow.WebAPI... --launch-profile http` (listens on `http://localhost:5161` and on the PC LAN IP for physical phone/tablet testing).

## Run

Each project is run independently from its own folder:

```powershell
cd AquaFlow/UI/aquaflow_desktop
flutter pub get
flutter run -d windows

cd AquaFlow/UI/aquaflow_customer
flutter pub get
flutter run                 # pick an Android/iOS device

cd AquaFlow/UI/aquaflow_collector
flutter pub get
flutter run                 # pick an Android/iOS device
```

> **Windows desktop:** building with native plugins (`flutter_secure_storage`) requires symlink support. If `flutter run -d windows` asks for it, enable **Developer Mode** (`start ms-settings:developers`).

### Seed login credentials (local demo DB)

`admin@aquaflow.ba`, `collector@aquaflow.ba`, `customer@aquaflow.ba` - all with password `AquaFlow123!`. Each account's role determines which of the 3 apps it can actually sign into - e.g. `customer@aquaflow.ba` is rejected (with an "Unavailable" screen) by `aquaflow_desktop` and `aquaflow_collector`.

## How auth works

Identical in all 3 projects (each has its own copy):

- `lib/shared/config/api_config.dart` - single source of the backend base URL. **Never hardcode the host anywhere else**; always read `ApiConfig.baseUrl`.
- `lib/shared/services/auth_api_service.dart` - calls `POST /Access/login`, `POST /Access/refresh`, `POST /Access/register`, mapping errors to a friendly `AuthException`.
- `lib/shared/services/token_storage.dart` - stores the access/refresh tokens in the platform secure store via `flutter_secure_storage`.
- `lib/shared/providers/auth_provider.dart` - the auth state (`provider`). On startup it restores a session from stored tokens (using the access token while valid, otherwise silently refreshing).
- `lib/shared/models/auth_session.dart` - decodes the JWT (`jwt_decoder`) into the signed-in user (`Email`, `UserRole`, `IsActive`, `Permission` claims).
- `lib/main.dart` - an `_AuthGate` shows splash / login / (authenticated) that project's `RoleGate` (`lib/app/role_gate.dart`), which checks the session's role and either shows that app's home screen or an `UnavailableScreen`.

## Host selection per platform

`ApiConfig.baseUrl` picks the host automatically (port `5161`):

| Target | Host used |
| --- | --- |
| Android emulator | `10.0.2.2` |
| iOS simulator, Windows, macOS, Linux | `localhost` |
| Physical phone | set `lanHostOverride` |

### Physical phone

A real device cannot reach your PC via `localhost`/`10.0.2.2`. Set `ApiConfig.lanHostOverride` (in that project's own `lib/shared/config/api_config.dart`) to your PC's LAN IP (e.g. `"192.168.1.20"`, find it with `ipconfig`) and make sure the phone is on the same Wi-Fi and the backend is reachable (bind it to `0.0.0.0` / allow it through the firewall).

## Local dev network settings (cleartext HTTP)

The backend serves plain **HTTP** in local dev, and mobile platforms block cleartext traffic by default. These **DEV-ONLY** exceptions are already in place in `aquaflow_customer` and `aquaflow_collector` (not needed on `aquaflow_desktop`, which never talks to an emulator's loopback restriction):

- **Android** - `android/app/src/debug/AndroidManifest.xml` sets `android:usesCleartextTraffic="true"` on `<application>`. It lives in the **debug** manifest, so release builds are unaffected.
- **iOS** - `ios/Runner/Info.plist` adds `NSAppTransportSecurity` > `NSAllowsLocalNetworking` (allows local/LAN cleartext without disabling ATS globally).

> ⚠️ **Production:** these are local development conveniences only. In production the backend must be served over **HTTPS**, and both exceptions must be removed (delete `usesCleartextTraffic` from the debug manifest / the `NSAppTransportSecurity` block from `Info.plist`) so the app rejects cleartext.

## Push notifications (Firebase Cloud Messaging)

Push only applies to `aquaflow_customer` and `aquaflow_collector` (there is no admin desktop push UI - `aquaflow_desktop` doesn't even depend on `firebase_core`). Each mobile project needs **its own** native config; none of it is committed (see each project's `.gitignore`). **This is a fresh registration for both mobile apps** - they do not reuse whatever Firebase app/config this repo may have used before the 3-way split.

### Android (do this once per mobile project)

1. In the [Firebase console](https://console.firebase.google.com/), add an Android app with package name `ba.aquaflow.aquaflow_customer` (for `aquaflow_customer`) or `ba.aquaflow.aquaflow_collector` (for `aquaflow_collector`), download **`google-services.json`**, and place it at that project's `android/app/google-services.json`.
2. That's it - `android/settings.gradle.kts` and `android/app/build.gradle.kts` already apply the `com.google.gms.google-services` Gradle plugin, which reads this file at build time. Without the file, `flutter build android` / `flutter run` targeting Android fails immediately with a clear "File google-services.json is missing" error - this is the expected state right after cloning, until you complete this step.
3. `POST_NOTIFICATIONS` (required on Android 13+ to actually show a notification) is declared in `android/app/src/main/AndroidManifest.xml`; the runtime prompt itself is requested by `PushNotificationService.requestPermissionAndRegister()` (see below).

### iOS (do this once per mobile project)

1. In the Firebase console, add an iOS app with bundle ID `ba.aquaflow.aquaflowCustomer` (for `aquaflow_customer`) or `ba.aquaflow.aquaflowCollector` (for `aquaflow_collector`), download **`GoogleService-Info.plist`**, and place it at that project's `ios/Runner/GoogleService-Info.plist`. Also drag it into the `Runner` target in Xcode (Runner.xcworkspace) so it's copied into the app bundle - adding the file on disk alone is not enough.
2. In Xcode, select the `Runner` target > **Signing & Capabilities** > **+ Capability** > **Push Notifications**. This can only be done from Xcode, not from code, and also requires an Apple Developer account with APNs enabled for that bundle ID.
3. `ios/Runner/AppDelegate.swift` calls `FirebaseApp.configure()` before the Flutter engine starts (needed so FirebaseMessaging's APNs wiring attaches early); `firebase_core`'s own `Firebase.initializeApp()` call from `main.dart` detects the already-configured app and is a no-op on iOS.
4. `firebase_core`/`firebase_messaging` ship CocoaPods podspecs only (no Swift Package Manager manifest yet), so each project - otherwise fully on SPM (see `ios/Flutter/ephemeral/Packages`) - needs `ios/Podfile` (the standard Flutter-generated template, already present) to pull them in via CocoaPods alongside the SPM plugins. Run `flutter pub get` then, on macOS, `pod install` from `ios/` (or just `flutter build ios` / `flutter run`, which does this for you) before opening `Runner.xcworkspace`.

### Client wiring

Runtime permission requests, device-token registration/refresh, and foreground/background/terminated message handling are all wired up client-side (identically in both mobile projects) - see `PushNotificationService`/`PushMessageHandler`/`AuthProvider` in `lib/shared/services` and `lib/shared/providers`. Only the native config above (the two developer-supplied files and the Xcode capability, per mobile project) still has to be done by hand per machine.
