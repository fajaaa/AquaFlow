using AquaFlow.Services.Database;

namespace AquaFlow.Services.InMemory;

public static class AquaFlowDataStore
{
    private static readonly DateTime SeedTime = DateTime.UtcNow;

    public static IList<User> Users { get; } = new List<User>
    {
        new()
        {
            Id = 1,
            Email = "admin@aquaflow.ba",
            PasswordHash = "demo-admin-hash",
            Phone = "+38733111222",
            Role = "Admin",
            IsActive = true,
            CreatedAt = SeedTime.AddDays(-30)
        },
        new()
        {
            Id = 2,
            Email = "collector@aquaflow.ba",
            PasswordHash = "demo-collector-hash",
            Phone = "+38761111222",
            Role = "Collector",
            IsActive = true,
            CreatedAt = SeedTime.AddDays(-20)
        },
        new()
        {
            Id = 3,
            Email = "customer@aquaflow.ba",
            PasswordHash = "demo-customer-hash",
            Phone = "+38762111222",
            Role = "Customer",
            IsActive = true,
            CreatedAt = SeedTime.AddDays(-15)
        }
    };

    public static IList<CustomerProfile> CustomerProfiles { get; } = new List<CustomerProfile>
    {
        new()
        {
            Id = 1,
            UserId = 3,
            FirstName = "Amina",
            LastName = "Hadziabdic",
            CustomerCode = "CUS-0001",
            DefaultLanguage = "bs",
            Theme = "light",
            CreatedAt = SeedTime.AddDays(-15)
        }
    };

    public static IList<CollectorProfile> CollectorProfiles { get; } = new List<CollectorProfile>
    {
        new()
        {
            Id = 1,
            UserId = 2,
            EmployeeCode = "COL-0001",
            AssignedAreaId = 1,
            CreatedAt = SeedTime.AddDays(-20)
        }
    };

    public static IList<Settlement> Settlements { get; } = new List<Settlement>
    {
        new()
        {
            Id = 1,
            Name = "Centar",
            City = "Sarajevo",
            PostalCode = "71000",
            CreatedAt = SeedTime.AddDays(-40)
        },
        new()
        {
            Id = 2,
            Name = "Ilidza",
            City = "Sarajevo",
            PostalCode = "71210",
            CreatedAt = SeedTime.AddDays(-40)
        }
    };

    public static IList<ServiceLocation> ServiceLocations { get; } = new List<ServiceLocation>
    {
        new()
        {
            Id = 1,
            CustomerId = 1,
            SettlementId = 1,
            Address = "Zmaja od Bosne 12",
            LocationType = "Apartment",
            Latitude = 43.855m,
            Longitude = 18.398m,
            IsActive = true,
            CreatedAt = SeedTime.AddDays(-14)
        }
    };

    public static IList<WaterMeter> WaterMeters { get; } = new List<WaterMeter>
    {
        new()
        {
            Id = 1,
            SerialNumber = "WM-2026-0001",
            ServiceLocationId = 1,
            InstalledAt = SeedTime.AddMonths(-6),
            Status = "Active",
            InitialReading = 120.50m,
            LastReading = 168.40m,
            CreatedAt = SeedTime.AddMonths(-6)
        }
    };

    public static IList<MeterReading> MeterReadings { get; } = new List<MeterReading>
    {
        new()
        {
            Id = 1,
            WaterMeterId = 1,
            CollectorId = 1,
            ReadingValue = 168.40m,
            PreviousReadingValue = 154.20m,
            ConsumptionM3 = 14.20m,
            ReadingDate = SeedTime.AddDays(-3),
            Source = "Collector",
            Note = "Redovno mjesecno ocitanje.",
            ClientUuid = "reading-demo-0001",
            SyncStatus = "Synced",
            SyncedAt = SeedTime.AddDays(-3).AddMinutes(10),
            CreatedAt = SeedTime.AddDays(-3)
        }
    };

    public static IList<Tariff> Tariffs { get; } = new List<Tariff>
    {
        new()
        {
            Id = 1,
            Name = "Domacinstvo 2026",
            CustomerType = "Customer",
            PricePerM3 = 1.35m,
            FixedFee = 3.50m,
            EffectiveFrom = new DateTime(2026, 1, 1),
            IsActive = true,
            CreatedAt = SeedTime.AddMonths(-6)
        }
    };

    public static IList<Invoice> Invoices { get; } = new List<Invoice>
    {
        new()
        {
            Id = 1,
            InvoiceNumber = "INV-2026-0001",
            CustomerId = 1,
            WaterMeterId = 1,
            BillingPeriodFrom = new DateTime(2026, 5, 1),
            BillingPeriodTo = new DateTime(2026, 5, 31),
            PreviousReading = 154.20m,
            CurrentReading = 168.40m,
            ConsumptionM3 = 14.20m,
            Subtotal = 22.67m,
            Tax = 3.85m,
            TotalAmount = 26.52m,
            Status = "Issued",
            DueDate = new DateTime(2026, 6, 15),
            CreatedById = 1,
            CreatedAt = SeedTime.AddDays(-3)
        }
    };

    public static IList<InvoiceItem> InvoiceItems { get; } = new List<InvoiceItem>
    {
        new()
        {
            Id = 1,
            InvoiceId = 1,
            TariffId = 1,
            Description = "Potrosnja vode",
            Quantity = 14.20m,
            UnitPrice = 1.35m,
            Amount = 19.17m,
            CreatedAt = SeedTime.AddDays(-3)
        },
        new()
        {
            Id = 2,
            InvoiceId = 1,
            TariffId = 1,
            Description = "Fiksna naknada",
            Quantity = 1,
            UnitPrice = 3.50m,
            Amount = 3.50m,
            CreatedAt = SeedTime.AddDays(-3)
        }
    };

    public static IList<Payment> Payments { get; } = new List<Payment>
    {
        new()
        {
            Id = 1,
            InvoiceId = 1,
            CustomerId = 1,
            Amount = 26.52m,
            PaymentMethod = "BankTransfer",
            Status = "Completed",
            PaidAt = SeedTime.AddDays(-1),
            TransactionReference = "BT-2026-0001",
            CreatedAt = SeedTime.AddDays(-1)
        }
    };

    public static IList<FaultReport> FaultReports { get; } = new List<FaultReport>
    {
        new()
        {
            Id = 1,
            ReportedById = 3,
            WaterMeterId = 1,
            ServiceLocationId = 1,
            Title = "Slab pritisak vode",
            Description = "Pritisak vode je nizak u jutarnjim satima.",
            Status = "New",
            Priority = "Medium",
            CreatedAt = SeedTime.AddDays(-2)
        }
    };

    public static IList<Notification> Notifications { get; } = new List<Notification>
    {
        new()
        {
            Id = 1,
            Title = "Planirani radovi",
            Body = "Planirani radovi na mrezi u naselju Centar.",
            Type = "PlannedWorks",
            Audience = "Settlement",
            SettlementId = 1,
            CreatedById = 1,
            ValidUntil = SeedTime.AddDays(5),
            CreatedAt = SeedTime.AddDays(-1)
        }
    };

    public static IList<UserNotification> UserNotifications { get; } = new List<UserNotification>
    {
        new()
        {
            Id = 1,
            UserId = 3,
            NotificationId = 1,
            ReadAt = null,
            CreatedAt = SeedTime.AddDays(-1)
        }
    };

    public static IList<CompanySettings> CompanySettings { get; } = new List<CompanySettings>
    {
        new()
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
            CreatedAt = SeedTime.AddDays(-45)
        }
    };

    public static IList<PaymentSettings> PaymentSettings { get; } = new List<PaymentSettings>
    {
        new()
        {
            Id = 1,
            AllowCardPayments = true,
            AllowPayPalPayments = false,
            CardProvider = "DemoPay",
            PayPalClientId = null,
            PayPalMerchantEmail = null,
            IsTestMode = true,
            UpdatedById = 1,
            CreatedAt = SeedTime.AddDays(-45),
            UpdatedAt = SeedTime.AddDays(-10)
        }
    };
}
