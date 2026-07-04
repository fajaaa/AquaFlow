# AquaFlow Agent Notes

This file gives AI coding agents the project map, current architecture, and working rules for this repository.

> Read this file first on every task. It is meant to save you from re-exploring the codebase. If something here is wrong or outdated, fix it as part of your change.

## Project Layout

Everything lives under the `AquaFlow/` directory at the repo root:

- `AquaFlow/AquaFlow.sln` - solution file.
- `AquaFlow/AquaFlow.WebAPI` - ASP.NET Core Web API host, controllers, JWT auth wiring (`Program.cs`), `Filters/ExceptionFilter`, and `Services/AccessManager`.
- `AquaFlow/AquaFlow.Services` - service/business logic layer, validators, EF Core `DbContext`/entities/migrations.
- `AquaFlow/AquaFlow.Model` - shared request/response DTOs, search objects, `Access` DTOs, exceptions, and simple contracts.
- `AquaFlow/AquaFlow.Common.Services` - cross-cutting services; currently `CryptoService` (`ICryptoService`) for password hashing.
- `AquaFlow/AquaFlow.Services.Tests` - xUnit test project for the service/business logic layer (EF Core InMemory provider). Run with `dotnet test .\AquaFlow\AquaFlow.Services.Tests\AquaFlow.Services.Tests.csproj`.
- `AquaFlow/AquaFlow.WebAPI.Tests` - xUnit test project for controllers. No database or HTTP host: tests new up a controller directly with a hand-written fake of the relevant `IBaseCRUDService<...>` (see `UserNotifications/FakeUserNotificationCrudService.cs`) and a `ClaimsPrincipal` built with the claims under test, then call the action method and assert on the returned `ActionResult`. This only exercises code inside the action body - `[RequirePermission(...)]` runs as an MVC authorization filter, not a plain method call, so it isn't reachable this way; where a test needs to pin that a write action is still gated, it asserts the attribute (and its permission code) via reflection instead of invoking the pipeline. Run with `dotnet test .\AquaFlow\AquaFlow.WebAPI.Tests\AquaFlow.WebAPI.Tests.csproj`.
- `AquaFlow/UI` - Flutter client (`aquaflow_desktop`), a cross-platform (desktop/mobile/web) frontend for the Web API. See the "UI (Flutter client)" section below.

## Runtime

The Web API targets `.NET 9`. All persistence is SQL Server through EF Core. There is no in-memory data store anymore (`AquaFlow.Services/InMemory` has been removed).

`Program.cs` throws at startup if either of these is missing, so they are required to run the API:

- `ConnectionStrings:DefaultConnection`
- `JwtToken:Issuer`, `JwtToken:Audience`, `JwtToken:SecretKey` (optional `JwtToken:DurationInMinutes`, default 60)

For convenience in this test project, `appsettings.json` now ships **dev-only** defaults for both the connection string and the JWT settings, so the API runs out of the box without extra setup. These are throwaway local values (same SA/demo password as the Docker container); do not treat them as real secrets and always override them via environment variables or user secrets outside local dev. The environment variables below still take precedence over `appsettings.json`, so use them to run against a different DB or to supply a real secret:

```powershell
$env:ConnectionStrings__DefaultConnection='Server=localhost,1435;Database=AquaFlow;User Id=sa;Password=AquaFlow123!;TrustServerCertificate=True;Encrypt=False'
$env:JwtToken__Issuer='AquaFlow'
$env:JwtToken__Audience='AquaFlowClients'
$env:JwtToken__SecretKey='<any-local-dev-secret-at-least-32-chars>'   # do NOT commit a real secret
$env:JwtToken__DurationInMinutes='60'
$env:ASPNETCORE_ENVIRONMENT='Development'
```

Build the solution:

```powershell
dotnet build .\AquaFlow\AquaFlow.sln
```

Run the SQL Server container (maps host port `1435` to container `1433`; use `localhost,1435` from the host):

```powershell
cd .\AquaFlow
docker compose up -d
```

Run the Web API locally (set the env vars above first; the `http` profile alone does not set the connection string or JWT settings):

```powershell
dotnet run --project .\AquaFlow\AquaFlow.WebAPI\AquaFlow.WebAPI.csproj --launch-profile http
```

Apply EF Core migrations locally (needs at least `ConnectionStrings__DefaultConnection`):

```powershell
dotnet ef database update --project .\AquaFlow\AquaFlow.Services --startup-project .\AquaFlow\AquaFlow.WebAPI
```

Local URLs (http profile listens on `5161` on all interfaces for mobile LAN testing, https on `7286`):

- `http://localhost:5161` - redirects to the API reference in development.
- `http://<PC-LAN-IP>:5161` - same API from a physical phone/tablet on the same Wi-Fi.
- `http://localhost:5161/scalar/v1` - Scalar API reference UI.
- `http://localhost:5161/Access/login` - obtain a JWT (see Authentication).
- `http://localhost:5161/Users`, `/UserRoles`, `/Permissions`, `/UserRolePermissions`, `/WaterMeters`, etc. - resource endpoints (require a JWT).

When running with only `--urls http://...`, the HTTPS redirect middleware logs `Failed to determine the https port for redirect` and does not redirect, so plain HTTP works for testing.

## Authentication & Authorization

Authentication is implemented with JWT bearer tokens.

- `BaseReadController` is annotated `[Authorize]`, so every controller deriving from `BaseReadController`/`BaseCRUDController` requires a valid bearer token. Unauthenticated calls return `401`.
- Granular authorization is layered on top of `[Authorize]` with `[RequirePermission("Code", ...)]` (`AquaFlow.WebAPI/Filters/RequirePermissionAttribute.cs`). It is a `TypeFilterAttribute` whose nested `IAuthorizationFilter` returns `401` when unauthenticated and `403` (`ForbidResult`) when the caller holds none of the listed permission codes. Codes are matched case-insensitively against `Permission` claims. Apply it per-action (see `UsersController` overriding `Create/Update/Patch/Delete` with `Users.Manage`, `NotificationsController` overriding all six CRUD actions - including `GetAll`/`GetById` - with `Notifications.Manage`, making `/Notifications` an admin-only endpoint over the raw, unfiltered table; the self-service read path for an ordinary user is `GET /UserNotifications/mine` instead) or at the controller class level (see `PermissionsController`/`UserRolesController`/`UserRolePermissionsController` with `Roles.Manage`). The base CRUD write actions are `virtual` so derived controllers can override them just to attach the attribute; `BaseReadController.GetAll`/`GetById` are also `virtual` (return `ActionResult<...>`) so a resource can override reads too when self-service ownership filtering is needed. Other CRUD controllers still carry a `// TODO: add [RequirePermission(...)]` marker until their final codes are defined.
- `NotificationsController` never trusts a client-supplied `CreatedById` (`NotificationInsertRequest`/`UpdateRequest`/`PatchRequest` all carry it, since `AquaFlow.Services.Tests` constructs those requests directly against `NotificationService` and needs to set it): `Create` overwrites it with the caller's own id from the JWT `Id` claim before calling `base.Create` (same pattern as `AccountController.GetCurrentUserId()`), so a `Notifications.Manage` holder cannot author a notification under someone else's name. `Update`/`Patch` instead fetch the existing row via `Service.GetByIdAsync` and force the request's `CreatedById` back to the existing value, so authorship can never be reassigned by an edit either (mirrors the FE, which already round-trips the original `createdById` on edit in `admin_notifications_screen.dart`).
- `UserNotificationsController` (`/UserNotifications`) is a self-service inbox with an admin escape hatch, combining both patterns above: `Create/Update/Delete` are overridden with `[RequirePermission("Notifications.Manage")]` (admin/system-only; rows are normally created by `NotificationService.InsertAsync`). `GetAll`/`GetById` are overridden without the attribute: a caller holding `Notifications.Manage` passes through unmodified (admin listing), otherwise the caller's id from the JWT `Id` claim is force-applied (`GetAll` pins `search.UserId`; `GetById` 404s - not `Forbid`, to avoid confirming another user's row exists - when the fetched row's `UserId` doesn't match). `Patch` is overridden with no permission attribute at all (an owner must be able to mark their own `ReadAt`) but does the same ownership check plus a mass-assignment guard: if the caller lacks `Notifications.Manage` and the request sets `UserId` or `NotificationId`, it throws `ClientException` before touching the service, so a caller can never patch someone else's row or reassign their own row's ownership - only `ReadAt` is self-editable. `GetMine` (`GET /UserNotifications/mine`) predates this and uses the same JWT-id-pinning pattern. Covered by `AquaFlow.WebAPI.Tests` (see Runtime section).
- `AccessController` (`/Access`) is anonymous: `POST /Access/login`, `POST /Access/refresh`, and `POST /Access/register` (public self-registration; always creates a `Customer`, ignoring any caller-supplied role).
- `AccountController` (`/Account`) is `[Authorize]` self-service for the signed-in user: `GET /Account/me`, `PUT /Account/me`, and `PUT /Account/me/password`. The user id always comes from the JWT `Id` claim (`ClaimNames.Id`), never from the request, so a caller can only ever read/edit their own record - which is why it needs no `Users.Manage` permission (the `UsersController` write actions do) and is safe for every role. `PUT /Account/me` takes `AccountUpdateRequest` (Email + Phone only) and calls `IUserService.UpdateOwnAccountAsync`, which updates only those two fields; role and active state are deliberately not self-editable anywhere (no privilege escalation). Password changes go through the separate `PUT /Account/me/password` instead: `AccountChangePasswordRequest` (CurrentPassword + NewPassword, validated by `AccountChangePasswordValidator` - both non-empty, NewPassword min 6 chars) is handled by `IUserService.ChangeOwnPasswordAsync`, which verifies `CurrentPassword` against the stored hash/salt via `ICryptoService.Verify` (throwing `ClientException` -> 400 on mismatch, so a stolen access token alone isn't enough to silently take over the password) before hashing and storing `NewPassword` with the existing `SetPassword` helper. `AccountUpdateValidator`/`AccountChangePasswordValidator` are registered in `Program.cs`.
- `AccessManager` validates credentials, issues the JWT (claims: id, email, userRole, isActive, plus one `Permission` claim per active permission of the user's role), and stores a refresh token (`RefreshToken` entity, 7-day expiry). Refresh rotates tokens. Permission codes for a role are resolved through `IPermissionLookupService` (`PermissionLookupService.GetPermissionCodesForRoleAsync`); keep that DB query in the service layer rather than in `AccessManager`.
- Refresh tokens are stored only as SHA-256 hashes (`RefreshTokenService.HashToken`): the raw value goes to the client, the DB row holds the hash, and lookups hash the incoming value before matching on the unique `RefreshToken.Token` index. `RefreshTokenService.InsertAsync` also purges expired tokens opportunistically. Do not persist raw refresh tokens.
- `/Access/login` and `/Access/refresh` are rate-limited (`RateLimitingPolicies.Authentication`, fixed window 5 requests/minute per client IP) via `AddRateLimiter`/`UseRateLimiter` in `Program.cs` and `[EnableRateLimiting]` on the actions.
- Every other request is throttled by a global limiter (`RateLimitingPolicies.Standard`, fixed window 300 requests/minute, set via `options.GlobalLimiter` in `Program.cs`), partitioned per authenticated user (JWT `Id` claim, available at this point since `UseAuthentication`/`UseAuthorization` run before `UseRateLimiter`) or per client IP for anonymous calls. A global limiter always stacks with any endpoint-specific policy rather than being overridden by it, so `/Access/login`/`/Access/refresh` still get the stricter 5/minute `Authentication` policy on top. This slows down scripted ID enumeration (e.g. `GET /UserNotifications/1`, `/2`, `/3`...) across all resource endpoints without needing a policy on every controller.
- Passwords are hashed with `ICryptoService` (PBKDF2 / `Rfc2898DeriveBytes`, SHA256, 10000 iterations, 20-byte hash, salt base64). Users store `PasswordHash` + `PasswordSalt`; never store plaintext.

Seed login credentials (local demo DB only; safe to use for testing): emails `admin@aquaflow.ba`, `collector@aquaflow.ba`, `customer@aquaflow.ba`, all with password `AquaFlow123!`.

To call a protected endpoint manually: `POST /Access/login` with `{"email":"admin@aquaflow.ba","password":"AquaFlow123!"}`, read `accessToken` from the response, then send `Authorization: Bearer <accessToken>`.

## UI (Flutter client)

The Flutter client lives in `AquaFlow/UI` (package `aquaflow_desktop`, Dart `^3.12`) and targets desktop, mobile and web from one codebase. Dependencies: `http`, `provider`, `flutter_secure_storage`, `jwt_decoder`. See `AquaFlow/UI/README.md` for run instructions and the local-dev network notes.

- Folder layout is **feature-based**, not type-based. `lib/main.dart` is the entry point; `lib/app/` holds the routing layer (`platform_gate.dart`, `mobile_role_router.dart`, `unavailable_screen.dart`); `lib/shared/` holds all cross-cutting code (`config/`, `theme/`, `models/`, `services/`, `providers/`, and role-agnostic `screens/` including the reusable `mobile_shell.dart`); `lib/admin/`, `lib/customer/`, `lib/collector/` hold the per-role screens. The dependency direction is one-way: `admin`/`customer`/`collector` -> `shared` (never the reverse). Inside `lib/shared/` the sub-structure mirrors the old flat layout so files there keep relative imports (`../models/...`); anything crossing a feature boundary uses package imports (`package:aquaflow_desktop/...`).
- Routing (platform + role) is staged in `main.dart` + `lib/app/`: (1) **web block** - `kIsWeb` short-circuits to `UnavailableScreen` before login (the app is desktop/mobile only, not a web app); (2) **auth gate** - `_AuthGate` renders splash / `LoginScreen` / (authenticated) `PlatformGate` from `AuthProvider.status`; (3) **platform + role** - `PlatformGate` allows only `admin` on desktop (Windows/macOS/Linux, detected via `defaultTargetPlatform`) -> `AdminDashboardScreen`, and blocks any other role with an `UnavailableScreen` (+ logout); on mobile/tablet (Android/iOS) `MobileRoleRouter` maps `customer` -> `CustomerShell`, `collector`/`admin` -> `CollectorShell` (an admin on a phone has no dedicated UI, so by product decision reuses the collector shell), else `UnavailableScreen`. Roles are matched case-insensitively on `session.userRole`. `UnavailableScreen` (`lib/app/unavailable_screen.dart`) is the shared dead-end (icon + title + message + optional "Odjava" button; omitted for the web block since there is no session yet).
- Base URL lives only in `lib/shared/config/api_config.dart` (`ApiConfig.baseUrl`, port 5161). It picks the host per platform: `10.0.2.2` on the Android emulator, `localhost` on iOS simulator/desktop/web, and `ApiConfig.lanHostOverride` (a compile-time constant, default `null`) for a physical phone. Never hardcode the host anywhere else - always read `ApiConfig.baseUrl`.
- Auth flow: `AuthApiService` (`lib/shared/services/auth_api_service.dart`) calls `POST /Access/login` and `POST /Access/refresh`, returning an `AuthResult` (`lib/shared/models/auth_result.dart`, the `{ accessToken, refreshToken }` pair) and mapping HTTP/transport failures to `AuthException`. `TokenStorage` (`flutter_secure_storage`) persists the access/refresh token pair. `AuthProvider` (a `ChangeNotifier`, `lib/shared/providers/auth_provider.dart`) is the single source of truth: `bootstrap()` restores a session on startup (valid access token, else silent refresh), `login()`/`logout()` mutate state. `AuthSession` (`lib/shared/models/auth_session.dart`) decodes the JWT via `jwt_decoder` using the backend claim names `Id`/`Email`/`UserRole`/`IsActive`/`Permission` (the `Permission` claim may decode to a string or a list; it is normalised to a list). See the Routing bullet above for how `main.dart` renders splash/login and hands an authenticated session to the platform/role gate.
- App shell (mobile): `MobileShell` (`lib/shared/screens/mobile_shell.dart`) is the reusable 4-tab bottom-nav scaffold (centered "AquaFlow" app bar with info + logout actions); it owns the selected-tab index and takes a list of `MobileTab`s. `CustomerShell` (`lib/customer/screens/customer_shell.dart`) and `CollectorShell` (`lib/collector/screens/collector_shell.dart`) each configure it with role-specific tabs; the 4th tab ("Nalog") is the shared `AccountScreen` in both, and placeholder tab bodies use the shared `PlaceholderTab`. The desktop admin home is `AdminDashboardScreen` (`lib/admin/screens/admin_dashboard_screen.dart`): a fixed left sidebar (brand + vertical menu with the active item highlighted in blue and a left indicator bar, plus an email/logout footer) and a content area that swaps with the selected menu item. The "Obavijesti" item sits directly below "Dashboard" and embeds `AdminNotificationsScreen` (`lib/admin/screens/admin_notifications_screen.dart`), a desktop CRUD table over `/Notifications` with search/filtering, create/edit modal, and delete; it uses `AdminNotificationService` (`lib/admin/services/admin_notification_service.dart`) and takes `CreatedById` from the JWT session. Backend notification publishing is handled by `NotificationService`: inserting a `Notification` resolves recipients with `NotificationRecipientService` and creates matching `UserNotification` inbox rows for `All`, `Customers`, `Collectors`, or `Settlement` audiences. `UserNotificationService.GetAllAsync` also backfills missing inbox rows for the signed-in user's visible notifications before `/UserNotifications/mine` returns, so older admin-created notifications can still appear on mobile. The "Postavke firme" item embeds the shared `CompanySettingsScreen`; "Moj nalog" embeds the admin-only `AdminAccountEditScreen` (see below - not the shared `AccountEditScreen` used by the mobile "Nalog" tab). "Korisnici" embeds `AdminUsersScreen` (`lib/admin/screens/admin_users_screen.dart`), a desktop CRUD table over `/Users` (search by name, role/status filters, paging, create/edit/delete) backed by `AdminUserService` (`lib/admin/services/admin_user_service.dart`); the table's "Ime i prezime" column and the search box both read/filter on the linked `CustomerProfile` (see the `UserResponse`/`UserSearchObject` bullet below). The create/edit dialog always shows the CustomerProfile fields (first/last name, language, theme) regardless of the selected role - not gated to Customer - since any user can optionally have a profile; a profile is only sent to the backend when the admin actually fills in a name (`_UserEditorDialogState._hasProfileInput`), calling `/CustomerProfiles` (POST if the user has none yet, PATCH if one already exists) alongside the `/Users` write. `CustomerCode` is never client-supplied: `CustomerProfileService` (`AquaFlow.Services/CustomerProfileService.cs`) generates it on insert (`CUS-0001`, `CUS-0002`, ... - sequential, backed by a unique index on `CustomerProfile.CustomerCode`) and pins the request's value back to the existing entity's code on update/patch, so it can never be reassigned; the FE only ever displays it as a disabled field once a profile exists. The other sections (Vodomjeri, Očitanja, Računi, Plaćanja, Prijave kvarova) are placeholders. The "Dashboard" item (index 0) shows three demo charts (line/donut/bar) drawn with `CustomPainter` and hard-coded values - colours come from the validated categorical palette (dataviz skill: blue/aqua/yellow/green), axis chrome from the muted/grid/baseline ink tokens - as a stand-in until the real dashboard is built.
- `AccountScreen` (`lib/shared/screens/account_screen.dart`, the "Nalog" tab) shows a role-specific avatar icon, the user's first+last name, and the role label only when the role is not `Customer` (a regular user). First/last name is NOT in the JWT - only `CustomerProfile` has it - so `ProfileService` (`lib/shared/services/profile_service.dart`) fetches it via `GET /CustomerProfiles?UserId={id}` and falls back to an email-derived name for admins/collectors (no customer profile) or on error. This is the template for authenticated resource fetches: read the token with `TokenStorage.getAccessToken()`, attach `Authorization: Bearer <token>`, and map failures to a resource-specific exception (e.g. `ProfileException`).
- Account edit (all users): `AccountScreen` shows an "Uredi nalog" card for every role that pushes `AccountEditScreen` (`lib/shared/screens/account_edit_screen.dart`), a form to edit the signed-in user's own email and phone. It loads via `AccountService.fetch()` (`GET /Account/me`, a single `UserResponse` object - not a `PageResult`) and saves via `AccountService.update()` (`PUT /Account/me`, body from `AccountDetails.toUpdateJson()` = email + phone only). The service follows the `CompanySettingsService` template and maps failures to `AccountException`. Note: the account screen's email display comes from the JWT (`session.email`), so an email change here is not reflected there until the next login/refresh reissues the token. This is the mobile customer/collector path; the admin desktop "Moj nalog" sidebar item uses a different, richer screen instead (see the next bullet).
- Admin account edit ("Moj nalog", desktop only): `AdminAccountEditScreen` (`lib/admin/screens/admin_account_edit_screen.dart`) occupies that one sidebar slot instead of the shared `AccountEditScreen`, extending it to the same editing depth as the "Korisnici" editor dialog (`_UserEditorDialog`) - minus role and active status, which stay off-limits for self-editing everywhere in this app. It still loads/saves email+phone through the same `AccountService`/`/Account/me`, and on top of that: (1) the signed-in admin's own CustomerProfile (first/last name, language, theme) through `AdminAccountService` (`lib/admin/services/admin_account_service.dart`), which fetches via `GET /CustomerProfiles?UserId=` and creates/updates via `POST`/`PATCH /CustomerProfiles` the same way `AdminUserService` does for other users - except every call targets the caller's own id and needs no `Users.Manage` permission - sent only when a first/last name was actually entered (`_hasProfileInput`, same all-or-nothing pairing as the Korisnici dialog); (2) a password change, sent only when the password fields are filled in (`_hasPasswordInput`), through `AdminAccountService.changePassword()` -> `PUT /Account/me/password`, which - unlike the Korisnici dialog, where an admin resetting someone else's password doesn't know their current one - requires the current password for confirmation. `AdminAccountService` reuses the shared `AccountException` type.
- Admin-only account action: when `session.userRole` is `admin`, `AccountScreen` shows a "Postavke firme" card that pushes `CompanySettingsScreen` (`lib/shared/screens/company_settings_screen.dart`, kept in `shared/` so the shared account tab and the admin dashboard can both reach it), a form to view/edit the single company-settings row. It loads via `CompanySettingsService.fetch()` (`GET /CompanySettings?PageSize=1`, first item) and saves via `CompanySettingsService.update()` (`PUT /CompanySettings/{id}`, body from `CompanySettings.toUpdateJson()` which omits the id). The service follows the `ProfileService` template and maps failures to `CompanySettingsException`, preferring the backend's `{ message, errors }` body. Gating is UI-side only for now — `CompanySettingsController` still carries the `// TODO: add [RequirePermission(...)]` marker, so any authenticated user can hit the endpoint until a permission code is added there.
- The backend serves plain HTTP in local dev, so DEV-ONLY cleartext exceptions are in place: `android/app/src/debug/AndroidManifest.xml` sets `android:usesCleartextTraffic="true"` (debug-only overlay, release stays secure) and `ios/Runner/Info.plist` adds `NSAppTransportSecurity` > `NSAllowsLocalNetworking`. These must be removed for production, where the backend must use HTTPS.
- Verify UI changes with `flutter analyze` and `flutter test` (run from `AquaFlow/UI`). Building the Windows desktop target needs symlink support (enable Windows Developer Mode) because the app uses a native plugin.
- Testing on a physical phone/tablet: set `ApiConfig.lanHostOverride` to the PC's LAN IP and run the backend with the `http` launch profile, which binds to all interfaces on port `5161`. Also allow inbound TCP 5161 through Windows Firewall (Private profile), and use `http://` explicitly in a browser (mobile browsers auto-upgrade to https, which the HTTP-only backend does not serve).

## Current Foundation

- The default branch is `main`; do feature work on feature branches.
- Persistence is EF Core + SQL Server end to end. EF infrastructure lives in `AquaFlow.Services/Database/AquaFlowDbContext.cs` (partial), migrations in `AquaFlow.Services/Migrations`, SQL Server registration in `AquaFlow.WebAPI/Program.cs`.
- SQL seed data is in `AquaFlow.Services/Database/AquaFlowDbContextSeed.cs` via the partial `CreateSeed(ModelBuilder)`; it covers user roles, permissions, role-permission assignments, users, settlements, company settings, profiles, service locations, water meters, readings, tariffs, invoices, payments, fault reports, and notifications. Use anonymous objects in `HasData` to avoid nullable/navigation issues.
- Entity classes are in `AquaFlow.Services/Database` and inherit `EntityBase` (`Id`, `CreatedAt`, `UpdatedAt`).
- Users link to roles through `UserRoleId` + the `UserRole` entity; do not reintroduce a free-form `User.Role` string. Role permissions are modeled through `Permission` + `UserRolePermission`; do not store permissions as comma-separated strings.
- `AquaFlowDbContext.OnModelCreating` sets all FK delete behavior to `Restrict` and declares unique indexes on `User.Email` (`IX_Users_Email`) and `RefreshToken.Token`. Keep these.
- Removed template artifacts stay removed: `Class1`, `WeatherForecast`, `WeatherForecastController`, and the default `/weatherforecast` sample.

## Architecture Rules

- Keep controllers in `AquaFlow.WebAPI/Controllers`; keep business logic in `AquaFlow.Services`; keep shared DTOs/contracts in `AquaFlow.Model`. Avoid business logic in controllers.
- Use `BaseReadController`/`BaseCRUDController` for standard endpoints.
- For standard CRUD, use the generic `EfCrudService<TEntity, TResponse, TSearch, TInsert, TUpdate, TPatch>`. Override its hooks instead of rewriting CRUD:
  - `IncludeForRead` / `IncludeForUpdate` for `.Include(...)` navigation loading.
  - `BeforeInsertAsync` / `BeforeUpdateAsync` / `BeforePatchAsync` for validation that needs the DB (uniqueness, reference existence). These run after FluentValidation and before entity mapping.
  - `LoadReferencesAsync` to load navigations after save (so the mapped response is populated).
- Use a resource-specific service (extending `EfCrudService`) when CRUD needs relationship wiring or uniqueness checks: see `PermissionService`, `UserRolePermissionService`, `CustomerProfileService`, `CollectorProfileService`. `UserService` extends `BaseCRUDService` directly and overrides `InsertAsync`/`UpdateAsync`/`PatchAsync` because it also manages password hashing.
- `Invoice` uses a State pattern instead of generic CRUD. `InvoiceService` (`IInvoiceService`) extends `EfCrudService` but is registered by hand in `Program.cs` (not via `AddCrud`); the generic `IBaseCRUDService<InvoiceResponse,...>` alias still resolves to it. Status transitions live in `AquaFlow.Services/InvoiceStateMachine`: `BaseInvoiceState` is a pure state (no factory) plus one class per status: Draft/Issued/PartiallyPaid/Overdue/Paid/Cancelled. Each state is registered in `Program.cs` as a keyed scoped `BaseInvoiceState` with the `InvoiceStatus` constant as the key, and `IInvoiceStateResolver`/`InvoiceStateResolver` resolves the state for a status via `GetRequiredKeyedService<BaseInvoiceState>(status)` (throwing `ClientException` (400) for an unknown status). `InvoiceService` depends on `IInvoiceStateResolver`. Each public transition (`Issue`/`RecordPayment`/`Cancel`/`MarkOverdue`) loads the tracked `Invoice` once in `InvoiceService`, resolves the state from `entity.Status`, and passes that entity into the state action (state actions take an `Invoice`, not an `int id`), so a transition is a single read instead of a status query plus a full re-read. `GetAllowedActionsAsync` still uses a status-only projection since it never mutates. Every transition goes through `BaseInvoiceState.TransitionToAsync`, which flips `Invoice.Status` and writes an `InvoiceStatusHistory` row in one `SaveChanges`. Disallowed transitions throw `ClientException` (400). `RecordPaymentInternalAsync` runs its read-balance/insert-payment/transition sequence inside a `Serializable` transaction so concurrent payments cannot both pass the balance check and overpay the invoice; because the entity was preloaded outside that transaction, it calls `DbContext.Entry(invoice).ReloadAsync()` to bring the invoice-row read (and its range lock) back inside the transaction alongside the payments-sum read. A full payment always transitions to `Paid`; for a partial payment each state passes its own `partialStatus` target into `RecordPaymentInternalAsync` (Overdue stays `Overdue` so the overdue marker is not lost, Issued/PartiallyPaid land on `PartiallyPaid`), and the `InvoiceStatusHistory` note records the resulting status. New invoices are forced to `Draft` in `BeforeInsertAsync`. Each state declares the `InvoiceStatus` it represents through an abstract `Status` property (used by `BaseInvoiceState.NotAllowed` for the rejection message) and advertises its permitted actions via `GetAllowedActions()`, whose verbs come from the `InvoiceAction` constants (`Issue`/`RecordPayment`/`Cancel`/`MarkOverdue`, the clean API verbs without the `Async` suffix); that list is hand-maintained and must stay in sync with the transition methods each state actually overrides. `InvoicesController` exposes `POST {id}/issue|payments|cancel|mark-overdue` and `GET {id}/allowed-actions`.
- Uniqueness convention: a private `EnsureUnique<X>Async(value, int? excludedId = null)` that throws `ClientException($"... already exists.")` when a conflicting row exists (`... && entity.Id != excludedId`). Call it before mapping; pass `excludedId: null` on insert and the entity id on update/patch. Examples: `UserService.EnsureUniqueEmailAsync`, `PermissionService.EnsureUniqueCodeAsync`, `UserRolePermissionService.EnsureUniqueAssignmentAsync`. Always back uniqueness with a DB unique index too.
- Throw `ClientException` for expected client errors (400), `KeyNotFoundException` for missing resources (404). `BaseCRUDController` and `ExceptionFilter` translate these (e.g. `ClientException` -> 400 `{ message, errors }`, FK violation on delete -> 400).
- Use FluentValidation validators in `AquaFlow.Services/Validators`; register each in `Program.cs`.
- Use Mapster for DTO/entity mapping. Patch requests map with `IgnoreNullValues(true)` via the `AddPatchMapping` helper.
- Keep EF Core model configuration in `AquaFlowDbContext` partials under `AquaFlow.Services/Database`.
- Keep connection strings and JWT secrets out of committed `appsettings*.json`; use environment variables or user secrets.

## API Conventions

- List endpoints (`GET /<Resource>`) return `PageResult<T>` = `{ "items": [...], "totalCount": <int?> }`. Paging/search comes from `BaseSearchObject`: `Page` (default 1), `PageSize` (default 10), `IncludeTotalCount` (default false), `SortBy` (entity property name, null = no sort), `SortDescending` (default false), plus resource-specific filters (e.g. `Users?Email=...&UserRoleId=...&UserRole=...&IsActive=...&Name=...`). `Users?Name=` matches (Contains) against the linked `CustomerProfile`'s `FirstName` OR `LastName` - a user with no `CustomerProfile` (admin/collector, or a customer with no profile yet) never matches it. `UserResponse.FirstName`/`LastName` are likewise flattened from `CustomerProfile` in the Mapster config in `Program.cs` (empty string when there is none); `UserService.GetDataSource()` includes `CustomerProfile` for both.
- Sorting in `BaseReadService.ApplySorting` is applied before paging using an Expression-tree key selector (no string-based/dynamic LINQ, no injection risk). An unknown `SortBy` is ignored (same lenient behaviour as filtering), and `SortBy` is matched case-insensitively against entity property names. To restrict which columns a resource can sort by, override `protected virtual HashSet<string>? SortableProperties` and return a whitelist; null (default) allows any existing entity property.
- Standard CRUD verbs per resource: `GET` (list), `GET /{id}`, `POST`, `PUT /{id}`, `PATCH /{id}`, `DELETE /{id}`.

## File Style

- One public type per `.cs` file. Do not group multiple entities, requests, responses, search objects, validators, interfaces, or controllers in one file.
- File name matches the public type, e.g. `WaterMeter.cs`, `WaterMeterResponse.cs`, `WaterMeterInsertValidator.cs`.
- Keep namespaces aligned with folders.
- Do not reintroduce generic template files like `Class1.cs`.

## Adding A New Resource

1. Add entity in `AquaFlow.Services/Database/{Name}.cs` (inherit `EntityBase`).
2. Add request DTOs in `AquaFlow.Model/Requests/{Name}InsertRequest.cs`, `{Name}UpdateRequest.cs`, `{Name}PatchRequest.cs`.
3. Add response DTO in `AquaFlow.Model/Responses/{Name}Response.cs` (inherit `AuditableResponse`).
4. Add search object in `AquaFlow.Model/SearchObjects/{Name}SearchObject.cs` (inherit `BaseSearchObject`).
5. Add validators in `AquaFlow.Services/Validators/{Name}InsertValidator.cs`, `{Name}UpdateValidator.cs`, `{Name}PatchValidator.cs`.
6. Add controller in `AquaFlow.WebAPI/Controllers/{Names}Controller.cs` (derive from `BaseCRUDController`).
7. Add the `DbSet<{Name}>` to `AquaFlowDbContext` and any model configuration in a `AquaFlowDbContext` partial.
8. Add EF seed data in `AquaFlowDbContextSeed.cs` if the SQL database should contain initial rows.
9. Register in `Program.cs`: simple resources use `AddCrud<...>()`; resources needing relationship wiring/uniqueness register a resource-specific `EfCrudService` subclass. Register all three validators.
10. Add and apply an EF Core migration if entity shape or SQL seed data changed.
11. Run `dotnet build .\AquaFlow\AquaFlow.sln`.

## Domain Notes

The domain is based on AquaFlow water utility models:

- users, user roles, permissions, customer profiles, collector profiles
- settlements, service locations, water meters
- meter readings, tariffs, invoices, invoice items, payments
- fault reports, notifications, user notifications
- company settings and payment settings
- additional entities such as assignments, routes, status history, alerts, sync operations, work orders, payment transactions, refresh tokens, and support tickets

Use existing classes before inventing new names. If an entity already exists in `AquaFlow.Services/Database`, extend it instead of creating a duplicate.

## Verification

Before finishing code changes, run:

```powershell
dotnet build .\AquaFlow\AquaFlow.sln
dotnet test .\AquaFlow\AquaFlow.Services.Tests\AquaFlow.Services.Tests.csproj
dotnet test .\AquaFlow\AquaFlow.WebAPI.Tests\AquaFlow.WebAPI.Tests.csproj
```

For a runtime smoke test, set the env vars (connection string + JWT) first, then run on a free port:

```powershell
dotnet run --no-build --project .\AquaFlow\AquaFlow.WebAPI\AquaFlow.WebAPI.csproj --urls http://localhost:5169
```

Resource endpoints require a bearer token, so log in first and reuse the `accessToken`:

- `POST http://localhost:5169/Access/login` body `{"email":"admin@aquaflow.ba","password":"AquaFlow123!"}`
- Then call `GET http://localhost:5169/Users?IncludeTotalCount=true` (and `/UserRoles`, `/Permissions`, `/UserRolePermissions?UserRoleId=1`, `/WaterMeters`) with `Authorization: Bearer <accessToken>`.
- `http://localhost:5169/scalar/v1` for the API reference.

Note: `dotnet ef` / `dotnet run` need the API DLLs unlocked. If a build or migration fails on locked DLLs, stop any running `AquaFlow.WebAPI` process first. If `database update` fails on `localhost,1433`, a local SQL Server is using that port; the Docker container is intentionally on host port `1435`.

## Git Notes

- Commit this file with the repository. Do not add `AGENTS.md` to `.gitignore`.
- Preserve user changes in the working tree; do not reset or revert unrelated edits.
- If private local instructions are ever needed, use a separate local-only file such as `AGENTS.local.md` and ignore that file instead.

## Security Notes

- Do not commit real secrets, production connection strings, API keys, payment provider secrets, JWT signing keys, or machine-specific settings. (The local SA/demo password `AquaFlow123!` used for the throwaway Docker container and seed users is local-only, not a real secret.) Exception: because this is a test project, `appsettings.json` intentionally carries dev-only defaults for the local DB connection string and a placeholder JWT `SecretKey` so it runs out of the box. Never point those at a real database or reuse that key in production — override with environment variables or user secrets there.
- Payment-related models must not store full card numbers, CVV values, raw provider passwords, private keys, or other sensitive payment data.
