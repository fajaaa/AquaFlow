using Microsoft.EntityFrameworkCore;

namespace AquaFlow.Services.Database;

public partial class AquaFlowDbContext : DbContext
{
    public AquaFlowDbContext(DbContextOptions<AquaFlowDbContext> options)
        : base(options)
    {
    }

    public DbSet<ActivityLog> ActivityLogs => Set<ActivityLog>();
    public DbSet<Attachment> Attachments => Set<Attachment>();
    public DbSet<BillingCycle> BillingCycles => Set<BillingCycle>();
    public DbSet<City> Cities => Set<City>();
    public DbSet<CollectorProfile> CollectorProfiles => Set<CollectorProfile>();
    public DbSet<CompanySettings> CompanySettings => Set<CompanySettings>();
    public DbSet<CustomerProfile> CustomerProfiles => Set<CustomerProfile>();
    public DbSet<DeviceToken> DeviceTokens => Set<DeviceToken>();
    public DbSet<Document> Documents => Set<Document>();
    public DbSet<FaultReport> FaultReports => Set<FaultReport>();
    public DbSet<FaultStatusHistory> FaultStatusHistories => Set<FaultStatusHistory>();
    public DbSet<Invoice> Invoices => Set<Invoice>();
    public DbSet<InvoiceItem> InvoiceItems => Set<InvoiceItem>();
    public DbSet<InvoiceStatusHistory> InvoiceStatusHistories => Set<InvoiceStatusHistory>();
    public DbSet<MeterAssignment> MeterAssignments => Set<MeterAssignment>();
    public DbSet<MeterReading> MeterReadings => Set<MeterReading>();
    public DbSet<MeterReplacement> MeterReplacements => Set<MeterReplacement>();
    public DbSet<Municipality> Municipalities => Set<Municipality>();
    public DbSet<Notification> Notifications => Set<Notification>();
    public DbSet<NotificationTemplate> NotificationTemplates => Set<NotificationTemplate>();
    public DbSet<Payment> Payments => Set<Payment>();
    public DbSet<PaymentMethod> PaymentMethods => Set<PaymentMethod>();
    public DbSet<PaymentSettings> PaymentSettings => Set<PaymentSettings>();
    public DbSet<PaymentTransaction> PaymentTransactions => Set<PaymentTransaction>();
    public DbSet<Permission> Permissions => Set<Permission>();
    public DbSet<ReadingRoute> ReadingRoutes => Set<ReadingRoute>();
    public DbSet<ReadingRouteItem> ReadingRouteItems => Set<ReadingRouteItem>();
    public DbSet<Recommendation> Recommendations => Set<Recommendation>();
    public DbSet<RefreshToken> RefreshTokens => Set<RefreshToken>();
    public DbSet<ServiceLocation> ServiceLocations => Set<ServiceLocation>();
    public DbSet<Settlement> Settlements => Set<Settlement>();
    public DbSet<SupportTicket> SupportTickets => Set<SupportTicket>();
    public DbSet<SyncOperation> SyncOperations => Set<SyncOperation>();
    public DbSet<Tariff> Tariffs => Set<Tariff>();
    public DbSet<TaxRate> TaxRates => Set<TaxRate>();
    public DbSet<User> Users => Set<User>();
    public DbSet<UserNotification> UserNotifications => Set<UserNotification>();
    public DbSet<UserPreference> UserPreferences => Set<UserPreference>();
    public DbSet<UserRole> UserRoles => Set<UserRole>();
    public DbSet<UserRolePermission> UserRolePermissions => Set<UserRolePermission>();
    public DbSet<WaterConsumptionAlert> WaterConsumptionAlerts => Set<WaterConsumptionAlert>();
    public DbSet<WaterMeter> WaterMeters => Set<WaterMeter>();
    public DbSet<WaterMeterRequest> WaterMeterRequests => Set<WaterMeterRequest>();
    public DbSet<WaterMeterRequestStatusHistory> WaterMeterRequestStatusHistories => Set<WaterMeterRequestStatusHistory>();
    public DbSet<WorkOrder> WorkOrders => Set<WorkOrder>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        foreach (var foreignKey in modelBuilder.Model.GetEntityTypes().SelectMany(entityType => entityType.GetForeignKeys()))
        {
            foreignKey.DeleteBehavior = DeleteBehavior.Restrict;
        }

        // Hot lookup columns: login resolves users by email, token refresh resolves by token value.
        // Without these indexes every login/refresh is a full table scan.
        modelBuilder.Entity<User>()
            .HasIndex(user => user.Email)
            .IsUnique()
            .HasFilter("[IsDeleted] = 0");

        modelBuilder.Entity<RefreshToken>()
            .HasIndex(token => token.Token)
            .IsUnique();

        // CustomerCode is generated server-side (CustomerProfileService.GenerateCustomerCodeAsync);
        // the unique index is the hard backstop behind that generation.
        modelBuilder.Entity<CustomerProfile>()
            .HasIndex(profile => profile.CustomerCode)
            .IsUnique();

        // EmployeeCode is generated server-side (CollectorProfileService.GenerateEmployeeCodeAsync);
        // the unique index is the hard backstop behind that generation.
        modelBuilder.Entity<CollectorProfile>()
            .HasIndex(profile => profile.EmployeeCode)
            .IsUnique();

        // Administrative lookup uniqueness is checked case-insensitively in the
        // EnsureUnique<X>Async methods of CityService/MunicipalityService/SettlementService;
        // these indexes are the hard backstop behind those checks (case-sensitive at the DB
        // level, but the app-level check is what actually prevents a case-only duplicate).
        // City: Name and Code globally unique.
        modelBuilder.Entity<City>()
            .HasIndex(city => city.Name)
            .IsUnique();

        modelBuilder.Entity<City>()
            .HasIndex(city => city.Code)
            .IsUnique();

        // Municipality: Name unique within its city, Code globally unique.
        modelBuilder.Entity<Municipality>()
            .HasIndex(municipality => new { municipality.CityId, municipality.Name })
            .IsUnique();

        modelBuilder.Entity<Municipality>()
            .HasIndex(municipality => municipality.Code)
            .IsUnique();

        // Settlement: Name unique within its municipality.
        modelBuilder.Entity<Settlement>()
            .HasIndex(settlement => new { settlement.MunicipalityId, settlement.Name })
            .IsUnique();

        // Optimistic concurrency for invoice status transitions: every UPDATE carries the
        // loaded RowVersion in its WHERE clause, so a stale transition affects 0 rows and
        // surfaces as DbUpdateConcurrencyException instead of silently overwriting.
        modelBuilder.Entity<Invoice>()
            .Property(invoice => invoice.RowVersion)
            .IsRowVersion();

        CreateSeed(modelBuilder);
    }
}
