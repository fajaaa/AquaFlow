# AquaFlow

AquaFlow is a management platform for a water utility company. It covers the operational
cycle end to end — customers and their water meters, field meter readings, tariff-based
invoicing, payments, new-connection requests, fault reports and customer support — through a
single ASP.NET Core Web API and three role-specific Flutter clients.

| Role | Client | Platforms | Scope |
| --- | --- | --- | --- |
| Admin | `aquaflow_desktop` | Windows / macOS / Linux | Users, tariffs, invoices, payments, location codebook, requests, fault reports, support tickets, notifications, company settings |
| Collector | `aquaflow_collector` | Android / iOS | Meter lookup, reading entry, assigned connection requests and fault reports |
| Customer | `aquaflow_customer` | Android / iOS | Own meters and invoices, invoice payment, new-connection requests, fault reports, support tickets, notification inbox |

---

## Table of contents

- [Features](#features)
- [Architecture](#architecture)
- [Technology stack](#technology-stack)
- [Prerequisites](#prerequisites)
- [Getting started](#getting-started)
- [Login credentials](#login-credentials)
- [Configuration](#configuration)
- [Security model](#security-model)
- [Hardening checklist before a non-local deployment](#hardening-checklist-before-a-non-local-deployment)
- [API overview](#api-overview)
- [Tests](#tests)
- [Troubleshooting](#troubleshooting)

---

## Features

**Identity and access control**
Users belong to a role (Admin, Collector, Customer); roles are granted fine-grained
permissions (for example `Invoices.Manage`, `MeterReadings.Manage`, `ActivityLogs.Read`)
rather than being checked by hard-coded role names. Authentication issues a short-lived JWT
access token plus a rotating refresh token. Self-registration always creates a Customer.

**Location codebook**
A City → Municipality → Settlement hierarchy backs every address in the system: customer
profiles, water meters, connection requests and fault reports.

**Water meters and readings**
Collectors search the meter register on site and submit a reading through a dedicated entry
endpoint. The server validates the reading (minimum 15-day spacing from the last billable
reading, no lower value than the previous one unless the meter was physically replaced,
retry-safe through a client-supplied idempotency key) and, when consumption is greater than
zero, generates the priced invoice in the same transaction.

**New-connection requests**
A customer requests service at an address, an administrator assigns it to a collector, and the
collector registers the physical meter on site. The request moves through
`Pending → Assigned → Registered | Rejected | Cancelled`.

**Tariffs and invoicing**
Administrators maintain price-per-m³ tariffs (several may be active at once, e.g. household
versus commercial). Invoices carry a year-scoped sequential number and move through
`Issued → Paid | Cancelled`; a partial payment keeps the invoice `Issued`. Cancelling an
invoice voids the reading it billed, so the consumption is re-billed by the next reading
instead of being silently lost.

**Payments**
A pluggable payment provider abstraction ships with a manual provider (payments recorded by
staff) and an optional Stripe provider that creates a PaymentIntent for the mobile
PaymentSheet flow and confirms the payment through a signed webhook.

**Fault reports and support tickets**
Customers report faults against their own account (with photo attachments) and staff triage
them through `New → Assigned → InProgress → Resolved`. Support tickets are threaded
conversations between a customer and staff, with photo attachments per message and an
`Open`/`Closed` lifecycle.

**Notifications**
Administrators publish notifications to an audience (everyone, all customers, all collectors,
or one settlement), optionally with images. Recipients get an in-app inbox with per-item read
state and an unread badge, plus a push notification on mobile via Firebase Cloud Messaging.

**Audit trail**
Security-relevant events (sign-in success and failure, token refresh, registration, password
and account changes, and administrative changes to another user's account) are written to an
activity log with a fixed retention window. Users can read their own history; the unfiltered
listing requires a dedicated permission.

**Company and payment settings, user preferences**
A single administrator-managed record holds company details and payment gateway
configuration. Each user has a persisted theme, language and notification preferences that the
clients apply on start-up.

---

## Architecture

Everything lives under the `AquaFlow/` directory.

### Backend — `AquaFlow/AquaFlow.sln`

| Project | Responsibility |
| --- | --- |
| [AquaFlow.WebAPI](AquaFlow/AquaFlow.WebAPI/) | HTTP host: controllers, JWT wiring, authorization filters, exception filter, rate limiting, OpenAPI |
| [AquaFlow.Services](AquaFlow/AquaFlow.Services/) | Business logic, validators, EF Core `DbContext`, entities, migrations, state machines, payment providers |
| [AquaFlow.Model](AquaFlow/AquaFlow.Model/) | Request/response DTOs, search objects, shared constants and exceptions |
| [AquaFlow.Common.Services](AquaFlow/AquaFlow.Common.Services/) | Cross-cutting services: password hashing, push notification delivery |
| [AquaFlow.Subscriber](AquaFlow/AquaFlow.Subscriber/) | Standalone console worker: consumes RabbitMQ notification messages independently of the API |
| [AquaFlow.Services.Tests](AquaFlow/AquaFlow.Services.Tests/) | xUnit tests for the business logic layer |
| [AquaFlow.WebAPI.Tests](AquaFlow/AquaFlow.WebAPI.Tests/) | xUnit tests for controller authorization and ownership rules |

Controllers derive from a generic read/CRUD base, so each resource inherits paging, filtering
and sorting, and adds only the authorization and ownership rules specific to it.

### Clients — `AquaFlow/UI`

Three independent Flutter projects, one per role, each with its own `pubspec.yaml` and its own
copy of the cross-cutting code (`lib/shared/`): there is intentionally no shared package
between them, so a change to shared logic must be applied in each project. See
[AquaFlow/UI/README.md](AquaFlow/UI/README.md) for the per-client run instructions, host
selection per platform, and Firebase setup.

---

## Technology stack

| Layer | Technology |
| --- | --- |
| API | C# / ASP.NET Core (.NET 9) |
| Persistence | EF Core 9 + SQL Server (migrations, no in-memory store) |
| Authentication | JWT bearer tokens, rotating refresh tokens, permission-based authorization |
| Validation / mapping | FluentValidation, Mapster |
| API documentation | OpenAPI + Scalar interactive reference |
| Payments | Provider abstraction; Stripe.NET for the Stripe provider |
| Push notifications | Firebase Admin SDK (server), `firebase_messaging` (clients) |
| Clients | Flutter (Dart `^3.12`), `provider` for state, `flutter_secure_storage` for tokens |
| Tests | xUnit (backend), `flutter test` / `flutter analyze` (clients) |

---

## Prerequisites

| Tool | Purpose | Verify |
| --- | --- | --- |
| [.NET 9 SDK](https://dotnet.microsoft.com/download) | Build and run the API | `dotnet --version` |
| [Docker Desktop](https://www.docker.com/products/docker-desktop/) | Local SQL Server instance | `docker --version` |
| [`dotnet-ef`](https://learn.microsoft.com/ef/core/cli/dotnet) | Apply migrations | `dotnet ef --version` |
| [Flutter SDK](https://docs.flutter.dev/get-started/install) | Build and run the clients (optional for backend-only work) | `flutter --version` |

Install the EF Core tools once if missing:

```powershell
dotnet tool install --global dotnet-ef
```

An external SQL Server instance can be used instead of Docker; only the connection string
changes.

---

## Getting started

All commands are PowerShell, run from the repository root.

### Quick start (Docker)

The fastest way to get the whole backend running — database, message broker, API, and the
notification worker — is `docker compose`:

```powershell
docker compose --file .\AquaFlow\docker-compose.yml up -d --build
```

This starts four containers on a shared network: `aquaflow-db` (SQL Server, host port `1435`),
`aquaflow-rabbitmq` (broker; AMQP on `5672`, management UI on `15672`), `aquaflow-api` (the Web
API, `http://localhost:5161`) and `aquaflow-subscriber` (the RabbitMQ notification worker). The
container credentials are development placeholders defined in
[docker-compose.yml](AquaFlow/docker-compose.yml); they are not intended for any shared or
hosted environment.

Migrations still have to be applied by hand (the API does not migrate on start-up):

```powershell
dotnet ef database update --project .\AquaFlow\AquaFlow.Services --startup-project .\AquaFlow\AquaFlow.WebAPI
```

That connects to the database over its host-mapped port (`localhost,1435`), so it works the
same whether SQL Server is running in Docker or locally. Then open
`http://localhost:5161/scalar/v1` to confirm the API is up, and skip ahead to
[Login credentials](#login-credentials) to sign in from a client.

To stop everything: `docker compose --file .\AquaFlow\docker-compose.yml down` (add `-v` to also
drop the database volume and start clean next time).

### Manual / local dev (step by step)

Use this instead of the Docker quick start when you want to run the API or worker from your IDE
(breakpoints, hot reload) rather than as a container. Only the database and broker run in
Docker; the API and worker run directly on your machine.

### 1. Start the database and broker

```powershell
docker compose --file .\AquaFlow\docker-compose.yml up -d aquaflow-db aquaflow-rabbitmq
```

This provisions a local-only SQL Server container reachable at `localhost,1435` (host port
`1435` maps to the container's `1433`, so it does not collide with a locally installed SQL
Server on `1433`) and a RabbitMQ broker reachable at `localhost:5672` (management UI at
`http://localhost:15672`, credentials `admin` / `admin`). Naming these two services explicitly
(rather than a bare `up -d`) skips building/starting the `aquaflow-api` and
`aquaflow-subscriber` containers, so they don't fight the local `dotnet run` instances below over
the same ports.

### 2. Configure the API

The API requires a connection string, JWT settings, and (optionally) a RabbitMQ connection
string, and fails fast at start-up if the first two are missing. None of these — nor any other
secret — are hardcoded in [appsettings.json](AquaFlow/AquaFlow.WebAPI/appsettings.json) or
anywhere else in source; they are supplied through `AquaFlow.WebAPI/.env`.

Copy the template and fill it in:

```powershell
Copy-Item .\AquaFlow\AquaFlow.WebAPI\.env.example .\AquaFlow\AquaFlow.WebAPI\.env
notepad .\AquaFlow\AquaFlow.WebAPI\.env
```

At minimum, set:

```env
ConnectionStrings__DefaultConnection=Server=localhost,1435;Database=AquaFlow;User Id=sa;Password=AquaFlow123!;TrustServerCertificate=True;Encrypt=False
JwtToken__Issuer=AquaFlow
JwtToken__Audience=AquaFlowClients
JwtToken__SecretKey=<random-value-at-least-32-characters>
RabbitMQ__ConnectionString=host=localhost;username=admin;password=admin
```

See [Configuration](#configuration) for the full key reference, why `.env` isn't committed, and
how the submitted archive replaces this step for a grader. `TrustServerCertificate=True` and
`Encrypt=False` are appropriate only for a local container; use an encrypted,
certificate-validated connection anywhere else.

### 3. Apply migrations

The schema and its reference data (roles, permissions, location codebook, tariffs, and demo
records for local testing) are created by the migrations:

```powershell
dotnet ef database update --project .\AquaFlow\AquaFlow.Services --startup-project .\AquaFlow\AquaFlow.WebAPI
```

### 4. Run the API (and, optionally, the worker)

```powershell
dotnet run --project .\AquaFlow\AquaFlow.WebAPI\AquaFlow.WebAPI.csproj --launch-profile http
```

The API listens on `http://localhost:5161` (bound to all interfaces so a phone or tablet on the
same network can reach it for testing). The `https` profile additionally listens on
`https://localhost:7286`.

The notification worker (`AquaFlow.Subscriber`) is a separate process; run it in its own
terminal if you want to see the RabbitMQ messages the API publishes actually get consumed:

```powershell
dotnet run --project .\AquaFlow\AquaFlow.Subscriber\AquaFlow.Subscriber.csproj
```

It only needs RabbitMQ (from step 1) to be running, not the API.

### 5. Verify

Open the interactive API reference (served in the `Development` environment only):

```
http://localhost:5161/scalar/v1
```

It lists every endpoint, its request and response shapes, and allows authenticated calls with a
bearer token.

### 6. Run a client

```powershell
cd .\AquaFlow\UI\aquaflow_desktop      # or aquaflow_customer / aquaflow_collector
flutter pub get
flutter run
```

Sign in with an account whose role matches the client; a role mismatch is rejected with an
"unavailable" screen. See [Login credentials](#login-credentials) below for accounts to sign in
with, or create your own through `POST /Access/register` (always creates a Customer).

---

## Login credentials

The migrations seed one demo account per role (see
[AquaFlowDbContextSeed.cs](AquaFlow/AquaFlow.Services/Database/AquaFlowDbContextSeed.cs)). These
are local-only development accounts — reset or remove them before deploying anywhere shared (see
[Hardening checklist](#hardening-checklist-before-a-non-local-deployment)).

| Role | Client | Email | Password |
| --- | --- | --- | --- |
| Admin | `aquaflow_desktop` | `kenan.fajic@aquaflow.ba` | `AquaFlow123!` |
| Collector | `aquaflow_collector` | `amel.fajic@aquaflow.ba` | `AquaFlow123!` |
| Collector | `aquaflow_collector` | `kemal.fajic@aquaflow.ba` | `AquaFlow123!` |
| Customer | `aquaflow_customer` | `denis.music@aquaflow.ba` | `AquaFlow123!` |
| Customer | `aquaflow_customer` | `elmir.babovic@aquaflow.ba` | `AquaFlow123!` |
| Customer | `aquaflow_customer` | `adil.joldic@aquaflow.ba` | `AquaFlow123!` |

Every seeded account uses the same password. The three seeded customers each own a different
number of water meters (3, 2 and 1 respectively), so switching between them is a quick way to
see accounts with more or less billing history. Signing in with an account whose role doesn't
match the client (e.g. a Customer email in `aquaflow_desktop`) is rejected with an "unavailable"
screen — use the matching client for the role you want to test.

---

## Configuration

Configuration is resolved by the standard ASP.NET Core provider chain. Later sources win:

1. `appsettings.json` — no secrets, committed. Only non-sensitive settings live here
   (`Logging`, `AllowedHosts`, `Payments:Provider`/`Payments:Currency`); the connection string,
   JWT settings and Stripe keys are omitted entirely, and `RabbitMQ:ConnectionString`/`Firebase:*`
   are present as explicit empty strings, since those two are optional and no-op cleanly when
   blank.
2. `appsettings.Development.json` — machine-local, git-ignored.
3. `AquaFlow.WebAPI/.env` — machine-local, git-ignored; loaded at start-up using the same
   `Section__Key` double-underscore convention as environment variables. Copy
   [.env.example](AquaFlow/AquaFlow.WebAPI/.env.example) and fill in your own values. A missing
   `.env` file is a silent no-op — which, since nothing lives in `appsettings.json` as a fallback
   anymore, means the API now fails fast (see below) unless something else in this chain
   supplies the required keys.
4. User secrets — `dotnet user-secrets set "JwtToken:SecretKey" "<value>" --project .\AquaFlow\AquaFlow.WebAPI`
5. Environment variables / the hosting platform's secret store.

| Key | Required | Notes |
| --- | --- | --- |
| `ConnectionStrings__DefaultConnection` | Yes | SQL Server connection string. Start-up fails if absent. |
| `JwtToken__Issuer`, `JwtToken__Audience` | Yes | Token issuer and audience. |
| `JwtToken__SecretKey` | Yes | Signing key, minimum 32 characters. Use a random, per-environment value. |
| `JwtToken__DurationInMinutes` | No | Access token lifetime, default `60`. |
| `RabbitMQ__ConnectionString` | No | Broker connection string (`host=...;username=...;password=...`). Blank registers a no-op publisher; every other feature keeps working. |
| `Payments__Provider` | No | `Manual` (default) or `Stripe`. |
| `Payments__Currency` | No | Currency code used for checkout amounts. |
| `Payments__Stripe__SecretKey` | If Stripe | Secret API key. Start-up fails if the provider is `Stripe` and this is blank. |
| `Payments__Stripe__WebhookSecret` | If Stripe | Webhook signing secret used to verify incoming events. |
| `Payments__Stripe__PublishableKey` | If Stripe | Served to the mobile client to initialise the payment sheet. |
| `Firebase__ServiceAccountJson` / `Firebase__ServiceAccountJsonPath` | No | Service account credential, inline or by path. |
| `Firebase__ProjectId` | No | Firebase project id. |

Push notifications are optional: with no Firebase credential configured, the API registers a
no-op sender and every other feature keeps working.

Never commit real values for any of the keys above — in particular the JWT signing key, the
database password, Stripe keys, and the Firebase service account JSON. `.env` files are
git-ignored for exactly this reason.

Generate a signing key:

```powershell
$bytes = New-Object byte[] 48
[System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
[Convert]::ToBase64String($bytes)
```

### Submitting `.env` for review

`AquaFlow.WebAPI/.env` is never committed. In its place,
`AquaFlow.WebAPI/.env-tajne.zip` — a password-protected (AES-256) ZIP archive containing the
same, real `.env` — **is** committed, so the repository still ships everything needed to run the
project without any code change, while no secret sits in plaintext in a public repository. To
use it: extract the archive with the password provided separately (through the course's DL
system, not in this repository) into `AquaFlow.WebAPI/`, so `.env` sits next to `.env-tajne.zip`
exactly as it does for local development. Regenerating the archive after changing `.env` requires
a small one-off script (`Ionic.Zip`/DotNetZip's `ZipFile.Password` + `EncryptionAlgorithm.WinZipAes256`
— .NET's built-in `System.IO.Compression` cannot write encrypted archives); it is not part of the
shipped solution.

---

## Security model

Authorization is enforced server-side, not by hiding actions in the user interface.

- **Authentication.** Every controller that derives from the read/CRUD base requires a valid
  bearer token; unauthenticated calls return `401`. Only `/Access/login`, `/Access/refresh`,
  `/Access/register` and the payment webhook are anonymous.
- **Permissions.** A `RequirePermission` authorization filter gates actions on permission codes
  carried as JWT claims (`403` when the caller is authenticated but not entitled). Codes are
  granted per role and stored in the database, so entitlements change without a code change.
- **Ownership pinning.** Self-service endpoints derive the acting user from the token's `Id`
  claim and ignore any client-supplied identity: a customer only ever sees their own profile,
  meters, invoices, requests, reports and tickets; a collector sees the work assigned to them.
  Write requests that carry an owner field have it forced back to the caller's own value, which
  blocks mass-assignment attempts.
- **Non-disclosure responses.** Reads outside the caller's scope return `404` rather than `403`,
  so a response never confirms that another user's record exists.
- **Password storage.** Passwords are hashed with PBKDF2 (SHA-256, per-user salt); plaintext is
  never stored. Changing a password requires the current one, so a stolen access token alone
  cannot take over an account.
- **Refresh tokens.** Only SHA-256 hashes are persisted; the raw token is returned to the client
  once. Refreshing rotates the token, expired tokens are purged, and a soft-deleted user's
  tokens are removed so the account can neither sign in nor refresh.
- **Rate limiting.** `/Access/login` and `/Access/refresh` are limited to 5 requests per minute
  per client IP; every other endpoint is covered by a global 300 requests per minute limit
  partitioned per authenticated user (or per IP when anonymous). Exceeded limits return `429`.
- **Enumeration resistance.** Failed sign-ins are logged only once a real user has been
  resolved, so an unknown email leaves no distinguishing trail, and unregister-style endpoints
  respond identically whether or not the target belongs to the caller.
- **File uploads.** Images are size-capped, count-capped per record, restricted to a format
  whitelist, and validated by magic-byte sniffing rather than by the client-supplied content
  type.
- **Audit trail.** Security events are recorded with the acting user, event type, IP address and
  timestamp. Log descriptions never contain passwords or tokens. Logging failures are swallowed
  so they cannot break the operation being audited.
- **Privilege escalation.** Role and active state are not self-editable through any endpoint;
  changing them requires the user-management permission and is written to the audit trail
  against the affected account.

## Hardening checklist before a non-local deployment

The defaults in this repository optimise for a zero-setup local run. Before deploying to any
shared or public environment:

1. Replace every placeholder value from [Configuration](#configuration) with a per-environment
   secret supplied by the platform's secret store — at minimum the connection string, the JWT
   signing key, and the Stripe keys.
2. Remove or reset the seeded demo accounts and any seeded credential.
3. Serve the API over HTTPS only, and remove the clients' development cleartext-HTTP
   exceptions (see [AquaFlow/UI/README.md](AquaFlow/UI/README.md)).
4. Replace the wildcard `AllowedHosts` with the real host list.
5. Confirm `ASPNETCORE_ENVIRONMENT` is not `Development` in the deployed environment: the
   permissive local-development CORS policy, the OpenAPI document and the interactive API
   reference are registered only for that environment, and must stay that way.
6. Use a least-privilege database account instead of a server administrator account, over an
   encrypted connection with certificate validation.
7. Review the retention window of the activity log against the applicable data-protection
   requirements.

---

## API overview

### Authenticating a request

1. `POST /Access/login` with `{ "email": "<email>", "password": "<password>" }`.
2. Read `accessToken` from the response.
3. Send `Authorization: Bearer <accessToken>` on every subsequent request.
4. When the access token expires, exchange the refresh token at `POST /Access/refresh`; both
   tokens are rotated.

The Flutter clients do this automatically and keep tokens in the platform secure store.

### Resources

| Area | Endpoints |
| --- | --- |
| Access & account | `/Access/login`, `/Access/refresh`, `/Access/register`, `/Account/me`, `/Account/me/password`, `/Account/preferences` |
| Users & roles | `/Users`, `/UserRoles`, `/Permissions`, `/UserRolePermissions`, `/CustomerProfiles`, `/CollectorProfiles` |
| Locations | `/Cities`, `/Municipalities`, `/Settlements` |
| Meters & readings | `/WaterMeters`, `/WaterMeterRequests`, `/MeterReadings`, `/Tariffs` |
| Billing | `/Invoices`, `/InvoiceItems`, `/Payments`, `/Payments/stripe-config`, `/Payments/webhook/stripe` |
| Support | `/FaultReports`, `/SupportTickets` |
| Messaging | `/Notifications`, `/UserNotifications`, `/DeviceTokens` |
| Operations | `/ActivityLogs`, `/CompanySettings`, `/PaymentSettings` |

Unless stated otherwise, a resource supports `GET` (list), `GET /{id}`, `POST`, `PUT /{id}`,
`PATCH /{id}` and `DELETE /{id}`. `/Payments` and `/ActivityLogs` are read-only — their rows are
written by the flows that produce them.

### Workflow endpoints

Records with a lifecycle are advanced through explicit transitions rather than a free-form
status edit, and each exposes `GET /{id}/allowed-actions` so a client can ask what is currently
permitted:

| Record | Transitions |
| --- | --- |
| Invoice | `POST /Invoices/{id}/checkout`, `/payments`, `/cancel` |
| Connection request | `POST /WaterMeterRequests/{id}/assign`, `/reject`, `/cancel`, `/register` |
| Fault report | `POST /FaultReports/{id}/assign`, `/start`, `/resolve` |
| Support ticket | `POST /SupportTickets/{id}/close`, `/reopen` |

Meter readings have their own entry points: `POST /MeterReadings/collector-entry` (validated
field entry, auto-invoicing, idempotent on retry) and `GET /MeterReadings/last-counting` (the
most recent reading that still counts towards billing). The generic `/MeterReadings` CRUD
surface remains available for administrative backfill.

### Paging, filtering and sorting

List endpoints return `{ "items": [ ... ], "totalCount": <int> }` and accept query parameters:

```
GET /Users?Page=2&PageSize=20&IncludeTotalCount=true&SortBy=Email&SortDescending=false
```

Each resource adds its own filters (for example `GET /WaterMeters?Term=<free-text>`,
`GET /Invoices?Status=Issued`, `GET /UserNotifications/mine?IsRead=false`).

### Status codes

| Code | Meaning |
| --- | --- |
| `400` | Validation error or business rule violation |
| `401` | Missing, expired or invalid token |
| `403` | Authenticated, but lacking the required permission |
| `404` | Not found, or outside the caller's scope |
| `429` | Rate limit exceeded |

---

## Tests

```powershell
# Business logic
dotnet test .\AquaFlow\AquaFlow.Services.Tests\AquaFlow.Services.Tests.csproj

# Controller authorization and ownership rules
dotnet test .\AquaFlow\AquaFlow.WebAPI.Tests\AquaFlow.WebAPI.Tests.csproj

# Compile everything
dotnet build .\AquaFlow\AquaFlow.sln
```

Backend tests run against the EF Core in-memory provider and need no database or HTTP host.
For a client, from its own project folder:

```powershell
flutter analyze
flutter test
```

---

## Troubleshooting

| Symptom | Cause and resolution |
| --- | --- |
| Start-up throws about the connection string or JWT configuration | A required key is missing. Set it through one of the mechanisms in [Configuration](#configuration). |
| Start-up throws about Stripe keys | `Payments__Provider` is `Stripe` but the secret or webhook key is blank. Supply both, or switch back to `Manual`. |
| Every request returns `401` | No or expired bearer token. Sign in again and send the `Authorization` header. |
| A request returns `403` | The account's role lacks the required permission. Grant the permission code, then sign in again — permissions are read from the token, so an existing session does not pick up a new grant. |
| A request returns `404` for a record you know exists | The record is outside the caller's scope; this is intentional non-disclosure. Use an account entitled to it. |
| `429 Too Many Requests` | A rate limit was hit — 5/minute on the authentication endpoints, 300/minute elsewhere. |
| `database update` fails against port `1433` | Another SQL Server occupies the default port. The container is published on `1435`; make sure the connection string says `localhost,1435`. |
| Build or migration fails with a locked file | The API is still running. Stop it (`Ctrl+C`) or terminate the stray `AquaFlow.WebAPI` process. |
| `dotnet ef` is not recognised | `dotnet tool install --global dotnet-ef` |
| A client cannot reach the API from a phone or emulator | See the host selection and local-network notes in [AquaFlow/UI/README.md](AquaFlow/UI/README.md). |
