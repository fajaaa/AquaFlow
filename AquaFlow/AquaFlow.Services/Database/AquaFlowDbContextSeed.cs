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
            });
    }

    private static void SeedUsers(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<User>().HasData(
            new
            {
                Id = 1,
                Email = "admin@aquaflow.ba",
                PasswordHash = "XohImNooBHFR0OniI2HVFw==",
                PasswordSalt = "AquaFlowSalt2026==",
                Phone = "+38733111222",
                UserRoleId = 1,
                IsActive = true,
                LastLoginAt = (DateTime?)null,
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            },
            new
            {
                Id = 2,
                Email = "collector@aquaflow.ba",
                PasswordHash = "XohImNooBHFR0OniI2HVFw==",
                PasswordSalt = "AquaFlowSalt2026==",
                Phone = "+38761111222",
                UserRoleId = 2,
                IsActive = true,
                LastLoginAt = (DateTime?)null,
                CreatedAt = SeedCreatedAt,
                UpdatedAt = (DateTime?)null
            },
            new
            {
                Id = 3,
                Email = "customer@aquaflow.ba",
                PasswordHash = "XohImNooBHFR0OniI2HVFw==",
                PasswordSalt = "AquaFlowSalt2026==",
                Phone = "+38762111222",
                UserRoleId = 3,
                IsActive = true,
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
}
