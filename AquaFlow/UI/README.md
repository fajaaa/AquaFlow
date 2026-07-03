# AquaFlow UI (`aquaflow_desktop`)

Flutter client for the AquaFlow backend (`AquaFlow.WebAPI`). Runs on Windows /
macOS / Linux desktop, Android, iOS and web from a single codebase. This
document covers the auth flow and the **local dev network settings** you need to
talk to the HTTP backend.

## Prerequisites

- Flutter SDK (Dart `^3.12`).
- The backend running locally. See the repo `AGENTS.md`: start SQL Server
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
