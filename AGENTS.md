# AquaFlow Agent Notes

This file gives AI coding agents the project map and working rules for this repository.

## Project Layout

- `AquaFlow/AquaFlow.sln` - solution file.
- `AquaFlow/AquaFlow.WebAPI` - ASP.NET Core Web API host.
- `AquaFlow/AquaFlow.Services` - service/business logic layer.
- `AquaFlow/AquaFlow.Model` - shared models and DTOs.

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
- `http://localhost:5161/weatherforecast` - sample API endpoint.

## Development Notes

- Keep controllers in `AquaFlow.WebAPI`.
- Keep business logic in `AquaFlow.Services`.
- Keep shared models, DTOs, and simple data contracts in `AquaFlow.Model`.
- Avoid placing business logic directly inside controllers.
- Prefer small, focused changes that follow the existing project structure.
- Do not commit secrets, connection strings, API keys, or machine-specific settings.

## Git Notes

Commit this file with the repository. Do not add `AGENTS.md` to `.gitignore`.

If private local instructions are ever needed, use a separate local-only file such as
`AGENTS.local.md` and ignore that file instead.
