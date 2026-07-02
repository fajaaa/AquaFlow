# AquaFlow 💧

AquaFlow is the backend (the "brain") for a **water utility company**. It keeps track of
customers, their water meters, meter readings, the invoices they get, the payments they
make, and problems they report. It's a web API written in **C# / ASP.NET Core (.NET 9)**.

> **What is a "web API"?** It's a program with no buttons or screens of its own. Other
> programs (a website, a mobile app, or a testing tool) talk to it over the internet by
> sending requests like "give me the list of users" and it sends back answers as data.

This README is the **for-dummies** guide: it assumes you've never touched this project and
walks you from zero to a running API. If you're an experienced dev (or an AI agent) and want
the deep technical rules, read [`AGENTS.md`](AGENTS.md) instead.

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

---

## 🗂️ How the project is organized

Everything lives inside the `AquaFlow/` folder. The code is split into small projects, each
with one job:

| Project | Plain-English job |
| --- | --- |
| `AquaFlow.WebAPI` | The front door. Receives web requests, checks logins, hands work to the services. |
| `AquaFlow.Services` | The workers. All the real logic, plus the database setup and data models. |
| `AquaFlow.Model` | The shapes of the data sent in and out (the "forms" and "receipts"). |
| `AquaFlow.Common.Services` | Shared helpers, e.g. password scrambling (`CryptoService`). |
| `AquaFlow.Services.Tests` | Automated tests that check the logic still works. |

`AquaFlow.sln` is the **solution file** — it just bundles all these projects together so one
command can build them all.

---

## 🚀 Getting it running (step by step)

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

### Step 3 — Create the database tables

The database is empty at first. This command builds all the tables and fills them with some
starter data (demo users, etc.):

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

## 🔑 Logging in (why most things say "401 Unauthorized")

Almost every command needs you to **log in first**. Logging in gives you a temporary pass
called a **token** (technically a JWT). You attach that token to every other request.

There are three ready-made demo accounts (local test database only):

| Email | Role | Password |
| --- | --- | --- |
| `admin@aquaflow.ba` | Admin | `AquaFlow123!` |
| `collector@aquaflow.ba` | Meter reader | `AquaFlow123!` |
| `customer@aquaflow.ba` | Customer | `AquaFlow123!` |

**How to log in:**

1. Send a `POST` request to `http://localhost:5161/Access/login` with this body:

   ```json
   { "email": "admin@aquaflow.ba", "password": "AquaFlow123!" }
   ```

2. The response contains an `accessToken`. Copy it.
3. On every other request, add a header:
   `Authorization: Bearer <paste-the-accessToken-here>`

That's it — now protected commands like `GET /Users` will work instead of returning `401`.

---

## 📚 What can the API do?

Each "resource" below supports the standard set of actions: **list them, get one, create,
update, and delete** (`GET`, `POST`, `PUT`, `PATCH`, `DELETE`).

- **People & access:** `/Users`, `/UserRoles`, `/Permissions`, `/UserRolePermissions`,
  `/CustomerProfiles`, `/CollectorProfiles`
- **Places & meters:** `/Settlements`, `/ServiceLocations`, `/WaterMeters`, `/MeterReadings`
- **Money:** `/Tariffs`, `/Invoices`, `/InvoiceItems`, `/Payments`
- **Support & messages:** `/FaultReports`, `/Notifications`, `/UserNotifications`
- **Configuration:** `/CompanySettings`, `/PaymentSettings`

**Invoices are special.** You don't just edit their status directly — you move them through
steps like *issue → record payment → cancel → mark overdue*. Those live at
`POST /Invoices/{id}/issue`, `/payments`, `/cancel`, `/mark-overdue`, and you can ask what's
allowed next with `GET /Invoices/{id}/allowed-actions`.

**Lists come in pages.** A list request returns `{ "items": [...], "totalCount": ... }`. You
can add options to the URL like `?Page=2&PageSize=20&IncludeTotalCount=true&SortBy=Email`.

---

## ✅ Running the tests

To check that the core logic still behaves:

```powershell
dotnet test .\AquaFlow\AquaFlow.Services.Tests\AquaFlow.Services.Tests.csproj
```

To just make sure everything compiles:

```powershell
dotnet build .\AquaFlow\AquaFlow.sln
```

---

## 🆘 Common problems

| Symptom | Likely cause & fix |
| --- | --- |
| App crashes on startup complaining about a connection string or JWT | The defaults in `appsettings.json` were removed or emptied. Put them back, or set the `$env:` variables from **Step 2**. |
| Everything returns `401 Unauthorized` | You're not logged in. Do the **login** steps and send the `Authorization: Bearer` header. |
| `database update` fails on port 1433 | Another SQL Server is using that port. Our Docker one is on **1435** on purpose — make sure your connection string says `localhost,1435`. |
| Build or migration fails saying a file is "locked" | The API is still running. Stop it (`Ctrl+C`) and try again. |
| `dotnet ef` is "not recognized" | Install it: `dotnet tool install --global dotnet-ef` |

---

## 📖 Want the deep dive?

This README covers the basics. The full architecture, coding rules, and conventions for
adding new features live in [`AGENTS.md`](AGENTS.md).
