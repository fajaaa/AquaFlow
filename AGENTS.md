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

## Runtime

The Web API targets `.NET 9`. All persistence is SQL Server through EF Core. There is no in-memory data store anymore (`AquaFlow.Services/InMemory` has been removed).

`Program.cs` throws at startup if either of these is missing, so they are required to run the API:

- `ConnectionStrings:DefaultConnection`
- `JwtToken:Issuer`, `JwtToken:Audience`, `JwtToken:SecretKey` (optional `JwtToken:DurationInMinutes`, default 60)

`appsettings.json` intentionally contains none of these (only logging/allowed hosts). Provide them via environment variables or user secrets. A convenient local block (PowerShell) used for run, migrations, and manual testing:

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

Local URLs (http profile listens on `5161`, https on `7286`):

- `http://localhost:5161` - redirects to the API reference in development.
- `http://localhost:5161/scalar/v1` - Scalar API reference UI.
- `http://localhost:5161/Access/login` - obtain a JWT (see Authentication).
- `http://localhost:5161/Users`, `/UserRoles`, `/Permissions`, `/UserRolePermissions`, `/WaterMeters`, etc. - resource endpoints (require a JWT).

When running with only `--urls http://...`, the HTTPS redirect middleware logs `Failed to determine the https port for redirect` and does not redirect, so plain HTTP works for testing.

## Authentication & Authorization

Authentication is implemented with JWT bearer tokens.

- `BaseReadController` is annotated `[Authorize]`, so every controller deriving from `BaseReadController`/`BaseCRUDController` requires a valid bearer token. Unauthenticated calls return `401`.
- `AccessController` (`/Access`) is anonymous: `POST /Access/login` and `POST /Access/refresh`.
- `AccessManager` validates credentials, issues the JWT (claims: id, email, userRole, isActive), and stores a refresh token (`RefreshToken` entity, 7-day expiry). Refresh rotates tokens.
- Passwords are hashed with `ICryptoService` (PBKDF2 / `Rfc2898DeriveBytes`, SHA256, 10000 iterations, 20-byte hash, salt base64). Users store `PasswordHash` + `PasswordSalt`; never store plaintext.

Seed login credentials (local demo DB only; safe to use for testing): emails `admin@aquaflow.ba`, `collector@aquaflow.ba`, `customer@aquaflow.ba`, all with password `AquaFlow123!`.

To call a protected endpoint manually: `POST /Access/login` with `{"email":"admin@aquaflow.ba","password":"AquaFlow123!"}`, read `accessToken` from the response, then send `Authorization: Bearer <accessToken>`.

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
- Uniqueness convention: a private `EnsureUnique<X>Async(value, int? excludedId = null)` that throws `ClientException($"... already exists.")` when a conflicting row exists (`... && entity.Id != excludedId`). Call it before mapping; pass `excludedId: null` on insert and the entity id on update/patch. Examples: `UserService.EnsureUniqueEmailAsync`, `PermissionService.EnsureUniqueCodeAsync`, `UserRolePermissionService.EnsureUniqueAssignmentAsync`. Always back uniqueness with a DB unique index too.
- Throw `ClientException` for expected client errors (400), `KeyNotFoundException` for missing resources (404). `BaseCRUDController` and `ExceptionFilter` translate these (e.g. `ClientException` -> 400 `{ message, errors }`, FK violation on delete -> 400).
- Use FluentValidation validators in `AquaFlow.Services/Validators`; register each in `Program.cs`.
- Use Mapster for DTO/entity mapping. Patch requests map with `IgnoreNullValues(true)` via the `AddPatchMapping` helper.
- Keep EF Core model configuration in `AquaFlowDbContext` partials under `AquaFlow.Services/Database`.
- Keep connection strings and JWT secrets out of committed `appsettings*.json`; use environment variables or user secrets.

## API Conventions

- List endpoints (`GET /<Resource>`) return `PageResult<T>` = `{ "items": [...], "totalCount": <int?> }`. Paging/search comes from `BaseSearchObject`: `Page` (default 1), `PageSize` (default 10), `IncludeTotalCount` (default false), `SortBy` (entity property name, null = no sort), `SortDescending` (default false), plus resource-specific filters (e.g. `Users?Email=...&UserRoleId=...&UserRole=...&IsActive=...`).
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

- Do not commit secrets, connection strings, API keys, payment provider secrets, JWT signing keys, or machine-specific settings. (The local SA/demo password `AquaFlow123!` used for the throwaway Docker container and seed users is local-only, not a real secret.)
- Payment-related models must not store full card numbers, CVV values, raw provider passwords, private keys, or other sensitive payment data.
