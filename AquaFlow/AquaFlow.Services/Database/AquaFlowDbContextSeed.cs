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
        SeedSettlements(modelBuilder);
        SeedCompanySettings(modelBuilder);
        SeedCustomerProfiles(modelBuilder);
        SeedCollectorProfiles(modelBuilder);
        SeedServiceLocations(modelBuilder);
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
            new
            {
                Id = 9,
                UserRoleId = 2,
                PermissionId = 6,
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            },
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
            });
    }

    private static void SeedUsers(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<User>().HasData(
            new
            {
                Id = 1,
                Email = "admin@aquaflow.ba",
                PasswordHash = "ILjw1fxwixrewU7K3VLOIm/0INU=",
                PasswordSalt = "AquaFlowSalt2026==",
                Phone = "+38733111222",
                UserRoleId = 1,
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
                Email = "collector@aquaflow.ba",
                PasswordHash = "ILjw1fxwixrewU7K3VLOIm/0INU=",
                PasswordSalt = "AquaFlowSalt2026==",
                Phone = "+38761111222",
                UserRoleId = 2,
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
                Email = "customer@aquaflow.ba",
                PasswordHash = "ILjw1fxwixrewU7K3VLOIm/0INU=",
                PasswordSalt = "AquaFlowSalt2026==",
                Phone = "+38762111222",
                UserRoleId = 3,
                IsActive = true,
                IsDeleted = false,
                DeletedAt = (DateTime?)null,
                LastLoginAt = (DateTime?)null,
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            });
    }

    private static void SeedSettlements(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Settlement>().HasData(
            new
            {
                Id = 1,
                Name = "Centar",
                City = "Sarajevo",
                PostalCode = "71000",
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            },
            new
            {
                Id = 2,
                Name = "Ilidza",
                City = "Sarajevo",
                PostalCode = "71210",
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            });
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
                UserId = 3,
                FirstName = "Amina",
                LastName = "Hadziabdic",
                CustomerCode = "CUS-0001",
                DefaultLanguage = "bs",
                Theme = "light",
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
                AssignedAreaId = (int?)1,
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            });
    }

    private static void SeedServiceLocations(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<ServiceLocation>().HasData(
            new
            {
                Id = 1,
                CustomerId = 1,
                SettlementId = 1,
                Address = "Zmaja od Bosne 12",
                LocationType = "Apartment",
                Latitude = (decimal?)43.855m,
                Longitude = (decimal?)18.398m,
                IsActive = true,
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            });
    }

    private static void SeedWaterMeters(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<WaterMeter>().HasData(
            new
            {
                Id = 1,
                SerialNumber = "WM-2026-0001",
                ServiceLocationId = 1,
                InstalledAt = new DateTime(2025, 12, 1, 0, 0, 0, DateTimeKind.Utc),
                Status = "Active",
                InitialReading = 120.50m,
                LastReading = 168.40m,
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            });
    }

    private static void SeedMeterReadings(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<MeterReading>().HasData(
            new
            {
                Id = 1,
                WaterMeterId = 1,
                CollectorId = 1,
                ReadingValue = 168.40m,
                PreviousReadingValue = 154.20m,
                ConsumptionM3 = 14.20m,
                ReadingDate = new DateTime(2026, 6, 1, 8, 0, 0, DateTimeKind.Utc),
                Source = "Collector",
                PhotoUrl = (string?)null,
                Note = "Redovno mjesecno ocitanje.",
                ClientUuid = "reading-demo-0001",
                SyncStatus = "Synced",
                SyncedAt = (DateTime?)new DateTime(2026, 6, 1, 8, 10, 0, DateTimeKind.Utc),
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            });
    }

    private static void SeedTariffs(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Tariff>().HasData(
            new
            {
                Id = 1,
                Name = "Domacinstvo 2026",
                CustomerType = "Customer",
                PricePerM3 = 1.35m,
                FixedFee = 3.50m,
                EffectiveFrom = new DateTime(2026, 1, 1, 0, 0, 0, DateTimeKind.Utc),
                EffectiveTo = (DateTime?)null,
                IsActive = true,
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            });
    }

    private static void SeedInvoices(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Invoice>().HasData(
            new
            {
                Id = 1,
                InvoiceNumber = "INV-2026-0001",
                CustomerId = 1,
                WaterMeterId = 1,
                BillingCycleId = (int?)null,
                BillingPeriodFrom = new DateTime(2026, 5, 1, 0, 0, 0, DateTimeKind.Utc),
                BillingPeriodTo = new DateTime(2026, 5, 31, 0, 0, 0, DateTimeKind.Utc),
                PreviousReading = 154.20m,
                CurrentReading = 168.40m,
                ConsumptionM3 = 14.20m,
                Subtotal = 22.67m,
                Tax = 3.85m,
                TotalAmount = 26.52m,
                Status = "Issued",
                DueDate = new DateTime(2026, 6, 15, 0, 0, 0, DateTimeKind.Utc),
                CreatedById = 1,
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            });
    }

    private static void SeedInvoiceItems(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<InvoiceItem>().HasData(
            new
            {
                Id = 1,
                InvoiceId = 1,
                TariffId = 1,
                TaxRateId = (int?)null,
                Description = "Potrosnja vode",
                Quantity = 14.20m,
                UnitPrice = 1.35m,
                Amount = 19.17m,
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            },
            new
            {
                Id = 2,
                InvoiceId = 1,
                TariffId = 1,
                TaxRateId = (int?)null,
                Description = "Fiksna naknada",
                Quantity = 1m,
                UnitPrice = 3.50m,
                Amount = 3.50m,
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            });
    }

    private static void SeedPayments(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Payment>().HasData(
            new
            {
                Id = 1,
                InvoiceId = 1,
                CustomerId = 1,
                Amount = 26.52m,
                PaymentMethod = "BankTransfer",
                Status = "Completed",
                PaidAt = (DateTime?)new DateTime(2026, 6, 2, 0, 0, 0, DateTimeKind.Utc),
                TransactionReference = "BT-2026-0001",
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            });
    }

    private static void SeedFaultReports(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<FaultReport>().HasData(
            new
            {
                Id = 1,
                ReportedById = 3,
                WaterMeterId = (int?)1,
                ServiceLocationId = 1,
                Title = "Slab pritisak vode",
                Description = "Pritisak vode je nizak u jutarnjim satima.",
                PhotoUrl = (string?)null,
                Status = "New",
                Priority = "Medium",
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
                Body = "Planirani radovi na mrezi u naselju Centar.",
                Type = "PlannedWorks",
                Audience = "Settlement",
                SettlementId = (int?)1,
                CreatedById = 1,
                ValidUntil = (DateTime?)new DateTime(2026, 6, 30, 0, 0, 0, DateTimeKind.Utc),
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
                UserId = 3,
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
