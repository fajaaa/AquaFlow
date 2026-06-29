# AquaFlow Agent Notes

This file gives AI coding agents the project map, current architecture, and working rules for this repository.

## Project Layout

- `AquaFlow/AquaFlow.sln` - solution file.
- `AquaFlow/AquaFlow.WebAPI` - ASP.NET Core Web API host and controllers.
- `AquaFlow/AquaFlow.Services` - service/business logic layer, validators, in-memory data, and domain entities.
- `AquaFlow/AquaFlow.Model` - shared request/response DTOs, search objects, exceptions, and simple contracts.

## Runtime

The Web API targets `.NET 9`.

Build the solution:

```powershell
dotnet build .\AquaFlow\AquaFlow.sln
```

Run the Web API locally:

```powershell
dotnet run --project .\AquaFlow\AquaFlow.WebAPI\AquaFlow.WebAPI.csproj --launch-profile http
```

Local URLs:

- `http://localhost:5161` - redirects to the API reference in development.
- `http://localhost:5161/scalar/v1` - Scalar API reference UI.
- `http://localhost:5161/Users` - sample AquaFlow endpoint.
- `http://localhost:5161/UserRoles` - user role lookup/CRUD endpoint.
- `http://localhost:5161/Permissions` - permission lookup/CRUD endpoint.
- `http://localhost:5161/UserRolePermissions` - role-permission assignment endpoint.
- `http://localhost:5161/WaterMeters` - sample AquaFlow endpoint.

## Current Foundation

- Foundation work is on branch `webapi-foundation`.
- The API currently uses generic read/CRUD infrastructure modeled after the RS2 eCommerce V1 example.
- Persistence is currently in-memory through `AquaFlow.Services/InMemory/AquaFlowDataStore.cs`.
- Entity classes are in `AquaFlow.Services/Database`.
- Users are linked to roles through `UserRoleId` and the `UserRole` entity; do not reintroduce a free-form `User.Role` string.
- Role permissions are modeled through `Permission` and `UserRolePermission`; do not store permissions as comma-separated strings.
- No real `DbContext`, migrations, authentication, authorization, or SQL persistence has been implemented yet unless added in a later iteration.
- Removed template artifacts should stay removed: `Class1`, `WeatherForecast`, `WeatherForecastController`, and the default `/weatherforecast` sample.

## Architecture Rules

- Keep controllers in `AquaFlow.WebAPI/Controllers`.
- Keep business logic and reusable service code in `AquaFlow.Services`.
- Keep shared DTOs and contracts in `AquaFlow.Model`.
- Avoid placing business logic directly inside controllers.
- Use `BaseReadController` and `BaseCRUDController` for standard endpoints.
- Use `BaseReadService`, `BaseCRUDService`, and `InMemoryCrudService` for current in-memory CRUD behavior.
- Use a resource-specific service when generic CRUD needs extra relationship wiring, such as `UserService` resolving `UserRoleId` to `UserRole`.
- Use `ExceptionFilter` for validation/client/server error responses.
- Use FluentValidation validators in `AquaFlow.Services/Validators`.
- Use Mapster for DTO/entity mapping.

## File Style

- One public type per `.cs` file.
- Do not group multiple entities, requests, responses, search objects, validators, interfaces, or controllers in one file.
- File name should match the public type name, for example `WaterMeter.cs`, `WaterMeterResponse.cs`, `WaterMeterInsertValidator.cs`.
- Keep namespaces aligned with folders.
- Do not reintroduce generic template files like `Class1.cs`.

## Adding A New Resource

When adding a new AquaFlow resource, follow this checklist:

1. Add entity in `AquaFlow.Services/Database/{Name}.cs`.
2. Add request DTOs in `AquaFlow.Model/Requests/{Name}InsertRequest.cs` and `{Name}UpdateRequest.cs`.
3. Add response DTO in `AquaFlow.Model/Responses/{Name}Response.cs`.
4. Add search object in `AquaFlow.Model/SearchObjects/{Name}SearchObject.cs`.
5. Add validators in `AquaFlow.Services/Validators/{Name}InsertValidator.cs` and `{Name}UpdateValidator.cs`.
6. Add controller in `AquaFlow.WebAPI/Controllers/{Names}Controller.cs`.
7. Add seed data to `AquaFlow.Services/InMemory/AquaFlowDataStore.cs` if the endpoint should return demo data.
8. Register the CRUD service and validators in `AquaFlow.WebAPI/Program.cs`.
9. Run `dotnet build .\AquaFlow\AquaFlow.sln`.

## Domain Notes

The domain is based on AquaFlow water utility models:

- users, user roles, permissions, customer profiles, collector profiles
- settlements, service locations, water meters
- meter readings, tariffs, invoices, invoice items, payments
- fault reports, notifications, user notifications
- company settings and payment settings
- additional planned entities such as assignments, routes, status history, alerts, sync operations, work orders, payment transactions, and support tickets

Use existing classes before inventing new names. If an entity from the model document already exists in `AquaFlow.Services/Database`, extend that class instead of creating a duplicate.

## Verification

Before finishing code changes, run:

```powershell
dotnet build .\AquaFlow\AquaFlow.sln
```

For a quick runtime smoke test:

```powershell
dotnet run --no-build --project .\AquaFlow\AquaFlow.WebAPI\AquaFlow.WebAPI.csproj --urls http://localhost:5169
```

Then check:

- `http://localhost:5169/Users?IncludeTotalCount=true`
- `http://localhost:5169/UserRoles?IncludeTotalCount=true`
- `http://localhost:5169/Permissions?IncludeTotalCount=true`
- `http://localhost:5169/UserRolePermissions?IncludeTotalCount=true&UserRoleId=1`
- `http://localhost:5169/Users?IncludeTotalCount=true&UserRole=Admin`
- `http://localhost:5169/WaterMeters?IncludeTotalCount=true`
- `http://localhost:5169/scalar/v1`

If build fails because DLL files are locked, check for an already running `AquaFlow.WebAPI` process and stop it before rebuilding.

## Git Notes

- Commit this file with the repository. Do not add `AGENTS.md` to `.gitignore`.
- Preserve user changes in the working tree; do not reset or revert unrelated edits.
- If private local instructions are ever needed, use a separate local-only file such as `AGENTS.local.md` and ignore that file instead.

## Security Notes

- Do not commit secrets, connection strings, API keys, payment provider secrets, or machine-specific settings.
- Payment-related models must not store full card numbers, CVV values, raw provider passwords, private keys, or other sensitive payment data.
