# Sistem preporuke — dokumentacija

Ovaj dokument opisuje modul preporuke/predikcije implementiran u AquaFlow-u, u skladu sa
zahtjevom predmeta Razvoj softvera II da aplikacija sadrži "jednostavniji modul sistema
preporuke korištenjem nekog od poznatih algoritama", uz objašnjive preporuke (korisniku se
mora objasniti *zašto* je nešto preporučeno/označeno).

## 1. Naziv modula i gdje se nalazi u kodu

**Consumption Insights** — otkrivanje neuobičajene potrošnje vode po vodomjeru, zasnovano na
predikciji vremenske serije (time series forecasting).

| Sloj | Lokacija |
| --- | --- |
| Algoritam (forecasting + anomaly detection) | [`AquaFlow.Services/Forecasting/ConsumptionForecastingService.cs`](AquaFlow/AquaFlow.Services/Forecasting/ConsumptionForecastingService.cs) |
| Poslovna logika / perzistencija preporuka | [`AquaFlow.Services/WaterConsumptionAlertService.cs`](AquaFlow/AquaFlow.Services/WaterConsumptionAlertService.cs) |
| Entitet | [`AquaFlow.Services/Database/WaterConsumptionAlert.cs`](AquaFlow/AquaFlow.Services/Database/WaterConsumptionAlert.cs) |
| API endpoint | [`AquaFlow.WebAPI/Controllers/WaterConsumptionAlertsController.cs`](AquaFlow/AquaFlow.WebAPI/Controllers/WaterConsumptionAlertsController.cs) (`/WaterConsumptionAlerts`) |
| Testovi | `AquaFlow.Services.Tests/Forecasting/ConsumptionForecastingServiceTests.cs`, `AquaFlow.Services.Tests/WaterConsumptionAlertServiceTests.cs`, `AquaFlow.WebAPI.Tests/ConsumptionAlerts/WaterConsumptionAlertsControllerTests.cs` |

## 2. Korišteni algoritam

Modul koristi **ML.NET** (`Microsoft.ML.TimeSeries`, v5.0.0) i konkretno **SSA — Singular
Spectrum Analysis**, standardni algoritam za analizu i predikciju vremenskih serija, primijenjen
na historiju očitanja potrošnje jednog vodomjera (`MeterReading.ConsumptionM3`, hronološki
poredano po datumu očitanja).

Algoritam se koristi u dvije faze, obje unutar `ConsumptionForecastingService.AnalyzeAsync`:

1. **Forecast** — `mlContext.Forecasting.ForecastBySsa(...)` predviđa sljedeću vrijednost
   potrošnje (`horizon: 1`) sa 95%-tnim intervalom pouzdanosti. Veličina prozora
   (`windowSize`) se automatski prilagođava dužini historije
   (`Math.Max(2, Math.Min((seriesLength - 1) / 2, 12))`), jer SSA zahtijeva da broj podataka za
   treniranje bude veći od dvostrukog prozora.
2. **Detekcija anomalije (spike)** — `DetectIidSpike` (kraće serije, < 12 očitanja) ili
   `DetectSpikeBySsa` (12+ očitanja) provjerava da li je **posljednje** očitanje statistički
   odstupanje (anomalija) u odnosu na dotadašnji obrazac potrošnje, uz 95%-tni prag pouzdanosti.

Ako vodomjer ima manje od 5 relevantnih (naplativih) očitanja, algoritam se uopšte ne pokreće
(`HasEnoughData = false`) — nema dovoljno podataka za pouzdanu analizu.

## 3. Ulazni podaci (moraju biti stvarno upisani u aplikaciji)

Ulaz algoritma je stvarna, upisana historija očitanja vodomjera: `MeterReading.ConsumptionM3`,
filtrirano na "naplativa" očitanja (`VoidedAt == null` i račun nije otkazan), tj. ista logika
koja se koristi i za obračun potrošnje na fakturi. Nema sintetičkih/mock podataka posebno
generisanih za preporuku — signal koji ulazi u model je isti podatak koji terenski saradnik
(Collector) unosi kroz `POST /MeterReadings/collector-entry`, pa se preporuka ažurira tako kako
stvarna potrošnja raste.

## 4. Kako nastaje preporuka (`WaterConsumptionAlert`)

`WaterConsumptionAlertService.RecomputeAsync` prolazi kroz sve aktivne vodomjere (ili jedan,
ako je zadan `waterMeterId`), poziva `AnalyzeAsync` za svaki, i **samo kada je otkrivena
anomalija** kreira zapis `WaterConsumptionAlert`:

- `MeasuredValue` — zadnje (anomalno) očitanje potrošnje;
- `ThresholdValue` — prosjek posljednje 3 naplative potrošnje istog mjerača (baseline "uobičajene"
  potrošnje);
- `Message` — tekstualno objašnjenje, npr.:
  `"Očitana potrošnja od 42 m³ za mjerač 000123 znatno odstupa od uobičajene potrošnje (8 m³)."`

Postoji idempotency provjera: dok god postoji nerazriješen (`IsResolved == false`) alert istog
tipa za isti mjerač, novi se ne kreira — sprječava gomilanje duplikata.

## 5. Objašnjive preporuke (explainability)

Preporuka nikad nije samo binarna oznaka "sumnjivo" — svaki zapis eksplicitno nosi **izmjerenu
vrijednost**, **prag/očekivanu vrijednost** i **tekstualno objašnjenje** zašto je baš ovaj
mjerač označen, čime administrator odmah vidi obrazloženje umjesto samo alarma bez konteksta.
Svi signali koji ulaze u bodovanje (izmjerena potrošnja, baseline, statistička anomalija iz
SSA modela) se stvarno koriste — nijedan se ne prikuplja pa zanemaruje.

## 6. Pokretanje i pristup

Modul se ne pokreće automatski u pozadini (nije zaseban worker), nego na zahtjev, isključivo
od strane administratora:

- `POST /WaterConsumptionAlerts/recompute` — preračunaj za sve aktivne mjerače;
- `POST /WaterConsumptionAlerts/recompute/{waterMeterId}` — preračunaj za jedan mjerač;
- `GET /WaterConsumptionAlerts` (i standardni CRUD) — pregled/upravljanje postojećim preporukama.

Cijeli kontroler je zaštićen `[Authorize(Roles engine via permission)] [RequirePermission("ConsumptionAlerts.Manage")]`
na nivou klase i dostupan je isključivo ulozi Admin, kroz desktop administratorski dio aplikacije
(izvještajni/upravljački modul).

## 7. Napomena o razvoju

Tokom razvoja je na ovoj grani kratko postojao paralelan resurs `Recommendation`
(predikcija rastuće-ali-ne-anomalne potrošnje), namijenjen krajnjem korisniku. Odlučeno je da
se zadrži samo `WaterConsumptionAlert` (anomaly-alert dio) kao jedini modul preporuke u
aplikaciji, pa je `Recommendation` u potpunosti uklonjen (kontroler, servis, entitet, migracija
`RemoveRecommendations`, seed permisija) kako bi implementacija tačno odgovarala ovom opisu.
