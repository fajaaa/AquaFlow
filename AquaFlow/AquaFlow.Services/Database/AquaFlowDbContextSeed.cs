using AquaFlow.Services.FaultReportStateMachine;
using Microsoft.EntityFrameworkCore;

namespace AquaFlow.Services.Database;

public partial class AquaFlowDbContext
{
    private static readonly DateTime SeedCreatedAt = new(2026, 1, 1, 0, 0, 0, DateTimeKind.Utc);

    private void CreateSeed(ModelBuilder modelBuilder)
    {
        SeedUserRoles(modelBuilder);
        SeedPermissions(modelBuilder);
        SeedUserRolePermissions(modelBuilder);
        SeedUsers(modelBuilder);
        SeedCities(modelBuilder);
        SeedMunicipalities(modelBuilder);
        SeedSettlements(modelBuilder);
        SeedCompanySettings(modelBuilder);
        SeedCustomerProfiles(modelBuilder);
        SeedCollectorProfiles(modelBuilder);
        SeedWaterMeters(modelBuilder);
        SeedMeterReadings(modelBuilder);
        SeedTariffs(modelBuilder);
        SeedInvoices(modelBuilder);
        SeedInvoiceItems(modelBuilder);
        SeedPayments(modelBuilder);
        SeedFaultReports(modelBuilder);
        SeedNotifications(modelBuilder);
        SeedUserNotifications(modelBuilder);
        SeedPaymentSettings(modelBuilder);
    }

    private static void SeedUserRoles(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<UserRole>().HasData(
            new
            {
                Id = 1,
                Name = "Admin",
                Description = "System administrator with full access.",
                IsActive = true,
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            },
            new
            {
                Id = 2,
                Name = "Collector",
                Description = "Field collector responsible for meter readings.",
                IsActive = true,
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            },
            new
            {
                Id = 3,
                Name = "Customer",
                Description = "Customer portal user.",
                IsActive = true,
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            });
    }

    private static void SeedPermissions(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Permission>().HasData(
            new
            {
                Id = 1,
                Code = "Users.Read",
                Name = "View users",
                Module = "Users",
                Description = "Allows reading user accounts.",
                IsActive = true,
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            },
            new
            {
                Id = 2,
                Code = "Users.Manage",
                Name = "Manage users",
                Module = "Users",
                Description = "Allows creating, updating, and deleting user accounts.",
                IsActive = true,
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            },
            new
            {
                Id = 3,
                Code = "MeterReadings.Manage",
                Name = "Manage meter readings",
                Module = "MeterReadings",
                Description = "Allows collectors to create and update meter readings.",
                IsActive = true,
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            },
            new
            {
                Id = 4,
                Code = "Invoices.Read",
                Name = "View invoices",
                Module = "Invoices",
                Description = "Allows reading invoices.",
                IsActive = true,
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            },
            new
            {
                Id = 5,
                Code = "Payments.Read",
                Name = "View payments",
                Module = "Payments",
                Description = "Allows reading payment records.",
                IsActive = true,
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            },
            new
            {
                Id = 6,
                Code = "FaultReports.Manage",
                Name = "Manage fault reports",
                Module = "FaultReports",
                Description = "Allows managing fault reports and related work.",
                IsActive = true,
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            },
            new
            {
                Id = 7,
                Code = "Notifications.Manage",
                Name = "Manage notifications",
                Module = "Notifications",
                Description = "Allows publishing and updating notifications.",
                IsActive = true,
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            },
            new
            {
                Id = 8,
                Code = "Roles.Manage",
                Name = "Manage roles and permissions",
                Module = "Roles",
                Description = "Allows managing user roles, permissions, and their assignments.",
                IsActive = true,
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            },
            new
            {
                Id = 9,
                Code = "WaterMeterRequests.Manage",
                Name = "Manage water meter requests",
                Module = "WaterMeterRequests",
                Description = "Allows assigning and rejecting water meter requests.",
                IsActive = true,
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            },
            new
            {
                Id = 10,
                Code = "Locations.Manage",
                Name = "Manage locations",
                Module = "Locations",
                Description = "Allows creating, updating, and deleting settlements and service locations.",
                IsActive = true,
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            },
            new
            {
                Id = 11,
                Code = "Tariffs.Manage",
                Name = "Manage tariffs",
                Module = "Tariffs",
                Description = "Allows creating, updating, and deleting tariffs.",
                IsActive = true,
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            },
            new
            {
                Id = 13,
                Code = "Invoices.Manage",
                Name = "Manage invoices",
                Module = "Invoices",
                Description = "Allows issuing, cancelling, and recording payments against invoices.",
                IsActive = true,
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            },
            new
            {
                Id = 14,
                Code = "CompanySettings.Manage",
                Name = "Manage company settings",
                Module = "CompanySettings",
                Description = "Allows viewing and editing company-wide settings.",
                IsActive = true,
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            },
            new
            {
                Id = 15,
                Code = "PaymentSettings.Manage",
                Name = "Manage payment settings",
                Module = "PaymentSettings",
                Description = "Allows viewing and editing payment gateway settings.",
                IsActive = true,
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            },
            new
            {
                Id = 16,
                Code = "ActivityLogs.Read",
                Name = "Pregled aktivnosti korisnika",
                Module = "ActivityLogs",
                Description = "Allows reading the security/activity audit trail for all users.",
                IsActive = true,
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            },
            new
            {
                Id = 17,
                Code = "SupportTickets.Manage",
                Name = "Manage support tickets",
                Module = "SupportTickets",
                Description = "Allows reading and responding to customer support tickets.",
                IsActive = true,
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            },
            new
            {
                Id = 18,
                Code = "Customers.Manage",
                Name = "Manage customers",
                Module = "Customers",
                Description = "Allows creating, updating, and deleting customer profiles.",
                IsActive = true,
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            },
            new
            {
                Id = 19,
                Code = "Collectors.Manage",
                Name = "Manage collectors",
                Module = "Collectors",
                Description = "Allows creating, updating, and deleting collector profiles.",
                IsActive = true,
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            },
            new
            {
                Id = 20,
                Code = "WaterMeters.Manage",
                Name = "Manage water meters",
                Module = "WaterMeters",
                Description = "Allows creating, updating, and deleting water meters.",
                IsActive = true,
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            },
            new
            {
                Id = 21,
                Code = "Invoices.Pay",
                Name = "Pay own invoices",
                Module = "Invoices",
                Description = "Allows a customer to check out and pay their own issued invoices.",
                IsActive = true,
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            });
    }

    private static void SeedUserRolePermissions(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<UserRolePermission>().HasData(
            new
            {
                Id = 1,
                UserRoleId = 1,
                PermissionId = 1,
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            },
            new
            {
                Id = 2,
                UserRoleId = 1,
                PermissionId = 2,
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            },
            new
            {
                Id = 3,
                UserRoleId = 1,
                PermissionId = 3,
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            },
            new
            {
                Id = 4,
                UserRoleId = 1,
                PermissionId = 4,
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            },
            new
            {
                Id = 5,
                UserRoleId = 1,
                PermissionId = 5,
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            },
            new
            {
                Id = 6,
                UserRoleId = 1,
                PermissionId = 6,
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            },
            new
            {
                Id = 7,
                UserRoleId = 1,
                PermissionId = 7,
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            },
            new
            {
                Id = 8,
                UserRoleId = 2,
                PermissionId = 3,
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            },
            // Id = 9 (Collector + FaultReports.Manage) was deliberately removed: a collector no
            // longer reads fault reports unfiltered - they are pinned to reports assigned to their
            // own CollectorProfile via FaultReport.AssignedCollectorId, same model as
            // WaterMeterRequests. Do not reuse the id.
            new
            {
                Id = 10,
                UserRoleId = 3,
                PermissionId = 4,
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            },
            new
            {
                Id = 11,
                UserRoleId = 3,
                PermissionId = 5,
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            },
            new
            {
                Id = 12,
                UserRoleId = 1,
                PermissionId = 8,
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            },
            new
            {
                Id = 13,
                UserRoleId = 1,
                PermissionId = 9,
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            },
            new
            {
                Id = 14,
                UserRoleId = 1,
                PermissionId = 10,
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            },
            new
            {
                Id = 15,
                UserRoleId = 1,
                PermissionId = 11,
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            },
            new
            {
                Id = 17,
                UserRoleId = 1,
                PermissionId = 13,
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            },
            new
            {
                Id = 18,
                UserRoleId = 1,
                PermissionId = 14,
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            },
            new
            {
                Id = 19,
                UserRoleId = 1,
                PermissionId = 15,
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            },
            new
            {
                Id = 20,
                UserRoleId = 1,
                PermissionId = 16,
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            },
            new
            {
                Id = 21,
                UserRoleId = 1,
                PermissionId = 17,
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            },
            new
            {
                Id = 22,
                UserRoleId = 1,
                PermissionId = 18,
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            },
            new
            {
                Id = 23,
                UserRoleId = 1,
                PermissionId = 19,
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            },
            new
            {
                Id = 24,
                UserRoleId = 1,
                PermissionId = 20,
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            },
            new
            {
                // Invoices.Pay is Customer-only (UserRoleId 3) - unlike every other Invoices.*/
                // Payments.* permission above, Admin does not hold this one: admin payments still
                // go through RecordPaymentAsync (Invoices.Manage), not the self-service checkout.
                Id = 25,
                UserRoleId = 3,
                PermissionId = 21,
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            });
    }

    // Login credentials for every seeded user (local demo DB only): password "AquaFlow123!",
    // same PBKDF2 hash/salt pair for all six accounts since the demo intentionally shares one password.
    private const string SeedPasswordHash = "ILjw1fxwixrewU7K3VLOIm/0INU=";
    private const string SeedPasswordSalt = "AquaFlowSalt2026==";

    private static void SeedUsers(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<User>().HasData(
            new
            {
                Id = 1,
                Email = "kenan.fajic@aquaflow.ba",
                PasswordHash = SeedPasswordHash,
                PasswordSalt = SeedPasswordSalt,
                Phone = "+38762111000",
                UserRoleId = 1,
                FirstName = "Kenan",
                LastName = "Fajic",
                IsActive = true,
                IsDeleted = false,
                DeletedAt = (DateTime?)null,
                LastLoginAt = (DateTime?)null,
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            },
            new
            {
                Id = 2,
                Email = "amel.fajic@aquaflow.ba",
                PasswordHash = SeedPasswordHash,
                PasswordSalt = SeedPasswordSalt,
                Phone = "+38761111001",
                UserRoleId = 2,
                FirstName = "Amel",
                LastName = "Fajic",
                IsActive = true,
                IsDeleted = false,
                DeletedAt = (DateTime?)null,
                LastLoginAt = (DateTime?)null,
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            },
            new
            {
                Id = 3,
                Email = "kemal.fajic@aquaflow.ba",
                PasswordHash = SeedPasswordHash,
                PasswordSalt = SeedPasswordSalt,
                Phone = "+38761111002",
                UserRoleId = 2,
                FirstName = "Kemal",
                LastName = "Fajic",
                IsActive = true,
                IsDeleted = false,
                DeletedAt = (DateTime?)null,
                LastLoginAt = (DateTime?)null,
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            },
            new
            {
                Id = 4,
                Email = "denis.music@aquaflow.ba",
                PasswordHash = SeedPasswordHash,
                PasswordSalt = SeedPasswordSalt,
                Phone = "+38762111004",
                UserRoleId = 3,
                FirstName = "",
                LastName = "",
                IsActive = true,
                IsDeleted = false,
                DeletedAt = (DateTime?)null,
                LastLoginAt = (DateTime?)null,
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            },
            new
            {
                Id = 5,
                Email = "elmir.babovic@aquaflow.ba",
                PasswordHash = SeedPasswordHash,
                PasswordSalt = SeedPasswordSalt,
                Phone = "+38762111005",
                UserRoleId = 3,
                FirstName = "",
                LastName = "",
                IsActive = true,
                IsDeleted = false,
                DeletedAt = (DateTime?)null,
                LastLoginAt = (DateTime?)null,
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            },
            new
            {
                Id = 6,
                Email = "adil.joldic@aquaflow.ba",
                PasswordHash = SeedPasswordHash,
                PasswordSalt = SeedPasswordSalt,
                Phone = "+38762111006",
                UserRoleId = 3,
                FirstName = "",
                LastName = "",
                IsActive = true,
                IsDeleted = false,
                DeletedAt = (DateTime?)null,
                LastLoginAt = (DateTime?)null,
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            });
    }

    // Real Canton Sarajevo data for the demo: the city "Sarajevo" pragmatically covers ALL
    // KS municipalities (including Vogosca/Hadzici/Ilijas/Trnovo, which are formally in the
    // canton rather than the city proper) so the lookup has one city with nine municipalities.
    private static void SeedCities(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<City>().HasData(
            new
            {
                Id = 1,
                Name = "Sarajevo",
                Code = "SA",
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            });
    }

    private static void SeedMunicipalities(ModelBuilder modelBuilder)
    {
        var municipalities = new (int Id, string Name, string Code)[]
        {
            (1, "Centar", "SA-01"),
            (2, "Novi Grad", "SA-02"),
            (3, "Novo Sarajevo", "SA-03"),
            (4, "Stari Grad", "SA-04"),
            (5, "Ilidza", "SA-05"),
            (6, "Vogosca", "SA-06"),
            (7, "Hadzici", "SA-07"),
            (8, "Ilijas", "SA-08"),
            (9, "Trnovo", "SA-09")
        };

        modelBuilder.Entity<Municipality>().HasData(
            municipalities.Select(municipality => new
            {
                municipality.Id,
                municipality.Name,
                municipality.Code,
                CityId = 1,
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            }));
    }

    private static void SeedSettlements(ModelBuilder modelBuilder)
    {
        // Ids 1 and 2 are referenced elsewhere in the seed (service location 1, collector
        // assigned area 1, notification 1), so they keep their ids and become real
        // settlements in the Centar and Ilidza municipalities.
        var settlements = new (int Id, string Name, int MunicipalityId, string PostalCode)[]
        {
            (1, "Bjelave", 1, "71000"),
            (2, "Hrasnica", 5, "71212"),
            (3, "Mejtas", 1, "71000"),
            (4, "Kosevo", 1, "71000"),
            (5, "Alipasino Polje", 2, "71000"),
            (6, "Dobrinja", 2, "71000"),
            (7, "Otoka", 2, "71000"),
            (8, "Grbavica", 3, "71000"),
            (9, "Hrasno", 3, "71000"),
            (10, "Pofalici", 3, "71000"),
            (11, "Bascarsija", 4, "71000"),
            (12, "Vratnik", 4, "71000"),
            (13, "Sokolovic Kolonija", 5, "71210"),
            (14, "Otes", 5, "71210"),
            (15, "Semizovac", 6, "71320"),
            (16, "Kobilja Glava", 6, "71320"),
            (17, "Blagovac", 6, "71320"),
            (18, "Pazaric", 7, "71240"),
            (19, "Tarcin", 7, "71240"),
            (20, "Binjezevo", 7, "71240"),
            (21, "Podlugovi", 8, "71380"),
            (22, "Mrakovo", 8, "71380"),
            (23, "Sabici", 9, "71223"),
            (24, "Dejcici", 9, "71223")
        };

        modelBuilder.Entity<Settlement>().HasData(
            settlements.Select(settlement => new
            {
                settlement.Id,
                settlement.Name,
                settlement.MunicipalityId,
                settlement.PostalCode,
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            }));
    }

    private static void SeedCompanySettings(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<CompanySettings>().HasData(
            new
            {
                Id = 1,
                CompanyName = "AquaFlow Vodovod",
                Address = "Obala Kulina bana 1, Sarajevo",
                Phone = "+38733000000",
                Email = "info@aquaflow.ba",
                TaxNumber = "4200000000000",
                BankAccount = "BA391234567890123456",
                DefaultLanguage = "bs",
                DefaultCurrency = "BAM",
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            });
    }

    private static void SeedCustomerProfiles(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<CustomerProfile>().HasData(
            new
            {
                Id = 1,
                UserId = 4,
                FirstName = "Denis",
                LastName = "Music",
                CustomerCode = "CUS-0001",
                DefaultLanguage = "bs",
                Theme = "light",
                SettlementId = (int?)8,
                Street = (string?)"Ozrenska",
                HouseNumber = (string?)"15",
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            },
            new
            {
                Id = 2,
                UserId = 5,
                FirstName = "Elmir",
                LastName = "Babovic",
                CustomerCode = "CUS-0002",
                DefaultLanguage = "bs",
                Theme = "light",
                SettlementId = (int?)6,
                Street = (string?)"Dobrinjske bolnice",
                HouseNumber = (string?)"7",
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            },
            new
            {
                Id = 3,
                UserId = 6,
                FirstName = "Adil",
                LastName = "Joldic",
                CustomerCode = "CUS-0003",
                DefaultLanguage = "bs",
                Theme = "light",
                SettlementId = (int?)11,
                Street = (string?)"Saraci",
                HouseNumber = (string?)"22",
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            });
    }

    private static void SeedCollectorProfiles(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<CollectorProfile>().HasData(
            new
            {
                Id = 1,
                UserId = 2,
                EmployeeCode = "COL-0001",
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            },
            new
            {
                Id = 2,
                UserId = 3,
                EmployeeCode = "COL-0002",
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            });
    }

    // Six meters across the three seeded customers (Denis: 3, Elmir: 2, Adil: 1), each with its own
    // settlement/street/house number so every meter has an exact, distinct service address.
    // HourlyConsumption holds one value per entry in ReadingTimestamps - a different consumption (and
    // so a different invoice amount) every hour, instead of a flat figure. Every value is a multiple
    // of 0.20 m3 so ConsumptionM3 * Tariff.PricePerM3 (1.35) lands on an exact 2-decimal amount for
    // every generated invoice line - no seeded rounding drift.
    private static readonly (int Id, string SerialNumber, int CustomerId, int SettlementId, string Street, string HouseNumber, decimal InitialReading, decimal[] HourlyConsumption, int CollectorId)[] WaterMeterPlan =
    {
        (1, "WM-2026-0001", 1, 8, "Ozrenska", "15", 80.00m, new[] { 12.20m, 15.80m, 10.40m, 16.60m, 14.20m }, 1),
        (2, "WM-2026-0002", 1, 9, "Behdzeta Mutevelica", "4", 60.00m, new[] { 8.20m, 11.40m, 9.80m, 7.60m, 10.60m }, 1),
        (3, "WM-2026-0003", 1, 1, "Mali Behar", "9", 95.00m, new[] { 13.00m, 9.40m, 12.80m, 14.60m, 10.20m }, 1),
        (4, "WM-2026-0004", 2, 6, "Dobrinjske bolnice", "7", 70.00m, new[] { 11.80m, 14.20m, 12.60m, 15.40m, 10.00m }, 2),
        (5, "WM-2026-0005", 2, 7, "Trg Oslobodjenja", "3", 55.00m, new[] { 9.00m, 11.60m, 8.40m, 12.20m, 10.80m }, 2),
        (6, "WM-2026-0006", 3, 11, "Saraci", "22", 40.00m, new[] { 10.60m, 13.40m, 11.20m, 14.80m, 9.60m }, 2),
    };

    // Five hourly readings per meter, same day (2026-06-01, 08:00-12:00 UTC); billing period for a
    // reading is always the one-hour window ending at it, so both readings and invoices run hourly.
    private static readonly DateTime[] ReadingTimestamps =
    {
        new(2026, 6, 1, 8, 0, 0, DateTimeKind.Utc),
        new(2026, 6, 1, 9, 0, 0, DateTimeKind.Utc),
        new(2026, 6, 1, 10, 0, 0, DateTimeKind.Utc),
        new(2026, 6, 1, 11, 0, 0, DateTimeKind.Utc),
        new(2026, 6, 1, 12, 0, 0, DateTimeKind.Utc),
    };

    // (WaterMeterId, ReadingTimestamps index) pairs whose invoice is left unpaid. Sized to hit the
    // requested counts exactly: Denis 12 paid/3 unpaid (meters 1-3, last hour each), Elmir 9 paid/1
    // unpaid (meter 4, last hour), Adil 3 paid/2 unpaid (meter 6, last two hours).
    private static readonly HashSet<(int MeterId, int HourIndex)> UnpaidInvoices = new()
    {
        (1, 4), (2, 4), (3, 4), (4, 4), (6, 3), (6, 4)
    };

    private static (DateTime From, DateTime To) GetBillingPeriod(DateTime readingDate) => (readingDate.AddHours(-1), readingDate);

    private static decimal GetInvoiceAmount(decimal consumptionM3) => consumptionM3 * 1.35m + 3.50m;

    private static IEnumerable<(int ReadingId, int MeterId, int HourIndex, decimal PreviousReading, decimal CurrentReading, decimal Consumption)> BuildReadingPlan()
    {
        var readingId = 1;
        foreach (var meter in WaterMeterPlan)
        {
            var previous = meter.InitialReading;
            for (var hourIndex = 0; hourIndex < ReadingTimestamps.Length; hourIndex++)
            {
                var consumption = meter.HourlyConsumption[hourIndex];
                var current = previous + consumption;
                yield return (readingId, meter.Id, hourIndex, previous, current, consumption);
                previous = current;
                readingId++;
            }
        }
    }

    private static void SeedWaterMeters(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<WaterMeter>().HasData(
            WaterMeterPlan.Select(meter => new
            {
                meter.Id,
                meter.SerialNumber,
                CustomerId = meter.CustomerId,
                SettlementId = meter.SettlementId,
                Street = (string?)meter.Street,
                HouseNumber = (string?)meter.HouseNumber,
                InstalledAt = new DateTime(2025, 12, 1, 0, 0, 0, DateTimeKind.Utc),
                Status = "Active",
                InitialReading = meter.InitialReading,
                LastReading = meter.InitialReading + meter.HourlyConsumption.Sum(),
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            }));
    }

    private static void SeedMeterReadings(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<MeterReading>().HasData(
            BuildReadingPlan().Select(reading =>
            {
                var meter = WaterMeterPlan.First(m => m.Id == reading.MeterId);
                var readingDate = ReadingTimestamps[reading.HourIndex];
                return new
                {
                    Id = reading.ReadingId,
                    WaterMeterId = reading.MeterId,
                    CollectorId = meter.CollectorId,
                    TariffId = (int?)1,
                    ReadingValue = reading.CurrentReading,
                    PreviousReadingValue = reading.PreviousReading,
                    ConsumptionM3 = reading.Consumption,
                    ReadingDate = readingDate,
                    Source = "Collector",
                    PhotoUrl = (string?)null,
                    Note = "Redovno satno ocitanje.",
                    ClientUuid = $"reading-wm{reading.MeterId:0000}-h{reading.HourIndex + 1:00}",
                    SyncStatus = "Synced",
                    SyncedAt = (DateTime?)readingDate.AddMinutes(10),
                    InvoiceId = (int?)reading.ReadingId,
                    VoidedAt = (DateTime?)null,
                    CreatedAt = SeedCreatedAt,
                    UpdatedAt = (DateTime?)null
                };
            }));
    }

    private static void SeedTariffs(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Tariff>().HasData(
            new
            {
                Id = 1,
                Name = "Domacinstvo 2026",
                Description = "Standardna tarifa za domaćinstva",
                PricePerM3 = 1.35m,
                IsActive = true,
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            });
    }

    private static void SeedInvoices(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Invoice>().HasData(
            BuildReadingPlan().Select(reading =>
            {
                var meter = WaterMeterPlan.First(m => m.Id == reading.MeterId);
                var (billingFrom, billingTo) = GetBillingPeriod(ReadingTimestamps[reading.HourIndex]);
                var isPaid = !UnpaidInvoices.Contains((reading.MeterId, reading.HourIndex));
                var amount = GetInvoiceAmount(reading.Consumption);
                return new
                {
                    Id = reading.ReadingId,
                    InvoiceNumber = $"INV-2026-{reading.ReadingId:0000}",
                    CustomerId = meter.CustomerId,
                    WaterMeterId = reading.MeterId,
                    BillingPeriodFrom = billingFrom,
                    BillingPeriodTo = billingTo,
                    PreviousReading = reading.PreviousReading,
                    CurrentReading = reading.CurrentReading,
                    ConsumptionM3 = reading.Consumption,
                    Subtotal = amount,
                    TotalAmount = amount,
                    Status = isPaid ? InvoiceStatus.Paid : InvoiceStatus.Issued,
                    CreatedById = 1,
                    CreatedAt = SeedCreatedAt,
                    UpdatedAt = (DateTime?)null
                };
            }));
    }

    private static void SeedInvoiceItems(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<InvoiceItem>().HasData(
            BuildReadingPlan().SelectMany(reading =>
            {
                var baseId = (reading.ReadingId - 1) * 2 + 1;
                return new[]
                {
                    new
                    {
                        Id = baseId,
                        InvoiceId = reading.ReadingId,
                        TariffId = 1,
                        Description = "Potrosnja vode",
                        Quantity = reading.Consumption,
                        UnitPrice = 1.35m,
                        Amount = reading.Consumption * 1.35m,
                        CreatedAt = SeedCreatedAt,
                        UpdatedAt = (DateTime?)null
                    },
                    new
                    {
                        Id = baseId + 1,
                        InvoiceId = reading.ReadingId,
                        TariffId = 1,
                        Description = "Fiksna naknada",
                        Quantity = 1m,
                        UnitPrice = 3.50m,
                        Amount = 3.50m,
                        CreatedAt = SeedCreatedAt,
                        UpdatedAt = (DateTime?)null
                    }
                };
            }));
    }

    private static void SeedPayments(ModelBuilder modelBuilder)
    {
        var paymentId = 1;
        var payments = new List<object>();
        foreach (var reading in BuildReadingPlan())
        {
            if (UnpaidInvoices.Contains((reading.MeterId, reading.HourIndex)))
            {
                continue;
            }

            var meter = WaterMeterPlan.First(m => m.Id == reading.MeterId);
            var (_, billingTo) = GetBillingPeriod(ReadingTimestamps[reading.HourIndex]);
            payments.Add(new
            {
                Id = paymentId,
                InvoiceId = reading.ReadingId,
                CustomerId = meter.CustomerId,
                Amount = GetInvoiceAmount(reading.Consumption),
                PaymentMethod = PaymentMethods[(paymentId - 1) % PaymentMethods.Length],
                Status = PaymentStatus.Completed,
                PaidAt = (DateTime?)billingTo.AddHours(2),
                Provider = PaymentProvider.Manual,
                ProviderTransactionId = $"PAY-2026-{paymentId:0000}",
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            });
            paymentId++;
        }

        modelBuilder.Entity<Payment>().HasData(payments);
    }

    private static readonly string[] PaymentMethods = { "BankTransfer", "Card", "Cash" };

    private static void SeedFaultReports(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<FaultReport>().HasData(
            new
            {
                Id = 1,
                ReportedById = 4,
                WaterMeterId = (int?)1,
                CustomerId = (int?)1,
                SettlementId = 8,
                Street = (string?)null,
                HouseNumber = (string?)null,
                Title = "Slab pritisak vode",
                Description = "Pritisak vode je nizak u jutarnjim satima.",
                PhotoUrl = (string?)null,
                Status = FaultReportStatus.New,
                ResolvedAt = (DateTime?)null,
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            });
    }

    private static void SeedNotifications(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Notification>().HasData(
            new
            {
                Id = 1,
                Title = "Planirani radovi",
                Body = "Planirani radovi na mrezi.",
                Type = "Info",
                Audience = "All",
                CreatedById = 1,
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            });
    }

    private static void SeedUserNotifications(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<UserNotification>().HasData(
            new
            {
                Id = 1,
                UserId = 4,
                NotificationId = 1,
                ReadAt = (DateTime?)null,
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            });
    }

    private static void SeedPaymentSettings(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<PaymentSettings>().HasData(
            new
            {
                Id = 1,
                AllowCardPayments = true,
                AllowPayPalPayments = false,
                CardProvider = "DemoPay",
                PayPalClientId = (string?)null,
                PayPalMerchantEmail = (string?)null,
                IsTestMode = true,
                UpdatedById = 1,
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)new DateTime(2026, 1, 10, 0, 0, 0, DateTimeKind.Utc)
            });
    }
}
