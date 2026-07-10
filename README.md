# AquaFlow 💧

AquaFlow is a full-stack management platform for a **water utility company**. It keeps
track of customers, their water meters, meter readings, tariffs, invoices, payments,
new-connection requests, and problems they report — and gives the company's admins,
field collectors, and customers each their own tailored app to work with that data.

The project has two halves:

- **Backend** — a web API written in **C# / ASP.NET Core (.NET 9)** that owns all the
  data and business logic.
- **Frontend** — a single **Flutter** codebase (`AquaFlow/UI`) that ships three different
  experiences from one app: an **admin desktop** console, a **customer mobile** app, and
  a **collector (meter reader) mobile** app.

> **What is a "web API"?** It's a program with no buttons or screens of its own. Other
> programs (a website, a mobile app, or a testing tool) talk to it over the internet by
> sending requests like "give me the list of users" and it sends back answers as data.

This README is the **for-dummies** guide: it assumes you've never touched this project
and walks you from zero to a running system.

---

## ✨ What it does

- **Accounts & access control** — users belong to a role (Admin / Collector / Customer)
  and roles are granted fine-grained permissions (e.g. `Invoices.Manage`), not a
  hard-coded role check. Login issues a JWT access token + refresh token.
- **Location codebook** — a City → Municipality → Settlement hierarchy backs every
  address in the system (customer addresses, meters, fault reports, requests).
- **Water meters & readings** — collectors search for a customer's meter on-site and
  submit a reading against the current open billing cycle; the reading is validated
  (no duplicates per cycle, no lower-than-last-reading without an explicit note) and
  automatically generates a draft invoice priced against the chosen tariff.
- **New-meter requests** — a customer requests service at an address; an admin assigns
  it to a collector, who registers the physical meter on-site. The whole request moves
  through a **Pending → Assigned → Registered / Rejected / Cancelled** state machine.
- **Tariffs & billing cycles** — admins manage price-per-m³ tariffs and open/close the
  billing period that meter readings and invoices are tied to.
- **Invoices & payments** — invoices move through a **Draft → Issued → PartiallyPaid /
  Overdue → Paid / Cancelled** state machine (`/Invoices/{id}/issue`, `/payments`,
  `/cancel`, `/mark-overdue`), with full/partial payments recorded against them.
- **Fault reports** — customers report problems (leaks, no water, etc.) against their
  own account; staff triage and manage them.
- **Notifications** — admins broadcast notifications (to everyone, all customers, all
  collectors, or a specific settlement); recipients see them in an in-app inbox and get
  a **push notification** on their phone (Firebase Cloud Messaging).
- **Company & payment settings** — a single admin-managed record for company details
  (name, contact info, tax number, bank account) and payment gateway configuration.

---

## 🧱 Tech stack

| Layer | Technology |
| --- | --- |
| Backend API | C# / ASP.NET Core (.NET 9), EF Core, SQL Server |
| Auth | JWT bearer tokens + refresh tokens, permission-based authorization |
| Validation & mapping | FluentValidation, Mapster |
| API docs | Scalar (interactive OpenAPI UI) |
| Push notifications | Firebase Admin SDK (server) / `firebase_messaging` (client) |
| Frontend | Flutter (Dart `^3.12`) — one codebase for desktop, Android, and iOS |
| State management | `provider` |
| Backend tests | xUnit (`AquaFlow.Services.Tests`, `AquaFlow.WebAPI.Tests`) |
| Frontend tests | `flutter test` / `flutter analyze` |

---

## 🗂️ How the project is organized

Everything lives inside the `AquaFlow/` folder.

### Backend — `AquaFlow/*.csproj`

The code is split into small projects, each with one job:

| Project | Plain-English job |
| --- | --- |
| `AquaFlow.WebAPI` | The front door. Receives web requests, checks logins, hands work to the services. |
| `AquaFlow.Services` | The workers. All the real logic, plus the database setup and data models. |
| `AquaFlow.Model` | The shapes of the data sent in and out (the "forms" and "receipts"). |
| `AquaFlow.Common.Services` | Shared helpers, e.g. password scrambling (`CryptoService`) and push notification sending. |
| `AquaFlow.Services.Tests` | Automated tests for the business logic. |
| `AquaFlow.WebAPI.Tests` | Automated tests for controller authorization/ownership rules. |

`AquaFlow.sln` is the **solution file** — it just bundles all these projects together so
one command can build them all.

### Frontend — `AquaFlow/UI`

One Flutter codebase, organized by feature and by role:

| Folder | What's in it |
| --- | --- |
| `lib/app/` | Routing: platform gate (desktop vs. mobile) and role router. |
| `lib/shared/` | Cross-cutting code every role uses: config, theme, models, services, providers. |
| `lib/admin/` | Desktop admin console (users, tariffs, invoices, payments, codebook, requests, notifications, settings). |
| `lib/customer/` | Mobile app for customers (meters, invoices, requests, notifications, account). |
| `lib/collector/` | Mobile app for field collectors (meter search, reading entry, assigned requests, notifications). |

See [`AquaFlow/UI/README.md`](AquaFlow/UI/README.md) for Flutter-specific run instructions
and local-network notes (talking to the backend from an emulator or a physical phone).

---

## 🧰 What you need installed first

You need three things on your computer before anything works:

| Tool | What it's for | How to check it's installed |
| --- | --- | --- |
| [.NET 9 SDK](https://dotnet.microsoft.com/download) | Builds and runs the C# code | `dotnet --version` |
| [Docker Desktop](https://www.docker.com/products/docker-desktop/) | Runs the database in a container | `docker --version` |
| A code editor | Visual Studio, VS Code, or Rider | — |

Run the two commands above in a terminal. If each prints a version number, you're good.
If it says "command not found", that tool isn't installed yet.

To also run the Flutter client, add the [Flutter SDK](https://docs.flutter.dev/get-started/install)
(`flutter --version`) — see [`AquaFlow/UI/README.md`](AquaFlow/UI/README.md) for that half.

---

## 🚀 Getting the backend running (step by step)

Do these in order. All commands are for **PowerShell** on Windows, run from the repo root
(the folder that contains this README).

### Step 1 — Start the database

The database (SQL Server) runs inside Docker so you don't have to install it yourself.

```powershell
cd .\AquaFlow
docker compose up -d
```

This starts a database and makes it reachable at `localhost,1435`. (`-d` means "in the
background".) Leave it running.

### Step 2 — (Optional) settings are already filled in

The app needs a **database address** and some **login/token settings** to start. Good news:
because this is a test project, [`appsettings.json`](AquaFlow/AquaFlow.WebAPI/appsettings.json)
already contains dev-only defaults for all of them, so **you can skip straight to Step 3.**

You only need to do something here if you want to point at a **different database** or use
your **own secret**. To do that, set environment variables (they override `appsettings.json`)
in the **same PowerShell window** you'll run the app from:

```powershell
$env:ConnectionStrings__DefaultConnection='Server=localhost,1435;Database=AquaFlow;User Id=sa;Password=AquaFlow123!;TrustServerCertificate=True;Encrypt=False'
$env:JwtToken__SecretKey='your-own-secret-at-least-32-chars'
$env:ASPNETCORE_ENVIRONMENT='Development'
```

> ⚠️ The values shipped in `appsettings.json` are **only for local testing**. Never point
> them at a real database or reuse that `SecretKey` in production — override it with
> environment variables or user secrets there. The `SecretKey` must be at least 32
> characters long.

Push notifications are optional too: `appsettings.json` ships an empty `Firebase` section,
so the backend falls back to a no-op sender and everything else keeps working without it.
To enable real pushes, set `Firebase__ServiceAccountJson` (or `...JsonPath`) and
`Firebase__ProjectId`.

### Step 3 — Create the database tables

The database is empty at first. This command builds all the tables and fills them with some
starter data (demo users, cities/municipalities/settlements, tariffs, etc.):

```powershell
dotnet ef database update --project .\AquaFlow\AquaFlow.Services --startup-project .\AquaFlow\AquaFlow.WebAPI
```

> Don't have the `dotnet ef` command? Install it once with:
> `dotnet tool install --global dotnet-ef`

### Step 4 — Run the API

```powershell
dotnet run --project .\AquaFlow\AquaFlow.WebAPI\AquaFlow.WebAPI.csproj --launch-profile http
```

The API is now live at **`http://localhost:5161`**. 🎉

---

## 🧪 Is it actually working?

Open your browser and go to:

**`http://localhost:5161/scalar/v1`**

This is the **API reference** — a clickable page that lists every command the API
understands and lets you try them out. If you see it, everything works.

---

## 📱 Running the Flutter client

Once the backend is running:

```powershell
cd AquaFlow\UI
flutter pub get
flutter run
```

- On **desktop** (Windows/macOS/Linux), the app only serves the **Admin** role.
- On **Android/iOS**, it routes **Customer** and **Collector** roles to their own mobile
  experience (an Admin signed in on a phone reuses the Collector shell).
- Web is intentionally blocked — this is a desktop/mobile app, not a web app.

See [`AquaFlow/UI/README.md`](AquaFlow/UI/README.md) for the local-network host settings
needed to reach the backend from an emulator or a physical device, and for the optional
Firebase push-notification setup.

---

## 🔑 Logging in (why most things say "401 Unauthorized")

Almost every command needs you to **log in first**. Logging in gives you a temporary pass
called a **token** (technically a JWT). You attach that token to every other request.

There are three ready-made demo accounts (local test database only):

| Email | Role | Password |
| --- | --- | --- |
| `admin@aquaflow.ba` | Admin | `AquaFlow123!` |
| `collector@aquaflow.ba` | Collector (meter reader) | `AquaFlow123!` |
| `customer@aquaflow.ba` | Customer | `AquaFlow123!` |

**How to log in (via the API directly):**

1. Send a `POST` request to `http://localhost:5161/Access/login` with this body:

   ```json
   { "email": "admin@aquaflow.ba", "password": "AquaFlow123!" }
   ```

2. The response contains an `accessToken`. Copy it.
3. On every other request, add a header:
   `Authorization: Bearer <paste-the-accessToken-here>`

That's it — now protected commands like `GET /Users` will work instead of returning `401`.
(The Flutter app does all of this for you through its own login screen.)

---

## 📚 What can the API do?

Each "resource" below supports the standard set of actions: **list them, get one, create,
update, and delete** (`GET`, `POST`, `PUT`, `PATCH`, `DELETE`), unless noted otherwise.

- **People & access:** `/Users`, `/UserRoles`, `/Permissions`, `/UserRolePermissions`,
  `/CustomerProfiles`, `/CollectorProfiles`, `/Account` (edit your own profile),
  `/DeviceTokens` (push notification registration)
- **Places:** `/Cities`, `/Municipalities`, `/Settlements`
- **Meters & billing:** `/WaterMeters`, `/WaterMeterRequests`, `/MeterReadings`,
  `/BillingCycles`, `/Tariffs`
- **Money:** `/Invoices`, `/InvoiceItems`, `/Payments`
- **Support & messages:** `/FaultReports`, `/Notifications`, `/UserNotifications`
- **Configuration:** `/CompanySettings`, `/PaymentSettings`

**Some resources move through a state machine instead of a free-form status edit:**

- **Invoices**: `POST /Invoices/{id}/issue`, `/payments`, `/cancel`, `/mark-overdue`, and
  `GET /Invoices/{id}/allowed-actions` to ask what's allowed next.
- **Water meter requests**: `POST /WaterMeterRequests/{id}/assign`, `/reject`, `/cancel`,
  `/register`, and `GET /WaterMeterRequests/{id}/allowed-actions`.
- **Meter readings**: collectors submit through the dedicated
  `POST /MeterReadings/collector-entry`, which also auto-generates the invoice for that
  reading in the same transaction.

**Who can see what is enforced server-side, not just hidden in the UI.** A Customer only
ever sees their own meters/invoices/requests/reports; a Collector sees the requests
assigned to them; write actions on shared/admin resources require a specific permission
(e.g. `Invoices.Manage`, `CompanySettings.Manage`) on top of just being logged in.

**Lists come in pages.** A list request returns `{ "items": [...], "totalCount": ... }`. You
can add options to the URL like `?Page=2&PageSize=20&IncludeTotalCount=true&SortBy=Email`.

---

## ✅ Running the tests

To check that the core business logic still behaves:

```powershell
dotnet test .\AquaFlow\AquaFlow.Services.Tests\AquaFlow.Services.Tests.csproj
```

To check controller-level authorization/ownership rules:

```powershell
dotnet test .\AquaFlow\AquaFlow.WebAPI.Tests\AquaFlow.WebAPI.Tests.csproj
```

To just make sure everything compiles:

```powershell
dotnet build .\AquaFlow\AquaFlow.sln
```

For the Flutter client, from `AquaFlow/UI`: `flutter analyze` and `flutter test`.

---

## 🆘 Common problems

| Symptom | Likely cause & fix |
| --- | --- |
| App crashes on startup complaining about a connection string or JWT | The defaults in `appsettings.json` were removed or emptied. Put them back, or set the `$env:` variables from **Step 2**. |
| Everything returns `401 Unauthorized` | You're not logged in. Do the **login** steps and send the `Authorization: Bearer` header. |
| A request returns `403 Forbidden` | You're logged in, but your role/permission doesn't allow that action (e.g. a Customer calling an Admin-only endpoint). |
| `database update` fails on port 1433 | Another SQL Server is using that port. Our Docker one is on **1435** on purpose — make sure your connection string says `localhost,1435`. |
| Build or migration fails saying a file is "locked" | The API is still running. Stop it (`Ctrl+C`), or stop the stray `AquaFlow.WebAPI` process, and try again. |
| `dotnet ef` is "not recognized" | Install it: `dotnet tool install --global dotnet-ef` |
| Flutter app can't reach the backend from a phone/emulator | See the local-network notes in [`AquaFlow/UI/README.md`](AquaFlow/UI/README.md) (host overrides, cleartext HTTP, firewall). |

---

## 📖 Want the deep dive?

This README covers the basics. Deeper architecture notes and coding conventions are kept
in a local, untracked `AGENTS.md` file for AI-assisted development — it isn't part of the
repository, so a fresh clone won't include it.
