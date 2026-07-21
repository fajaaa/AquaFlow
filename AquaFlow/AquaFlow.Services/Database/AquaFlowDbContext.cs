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
    public DbSet<FaultReportPhoto> FaultReportPhotos => Set<FaultReportPhoto>();
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
    public DbSet<Recommendation> Recommendations => Set<Recommendation>();
    public DbSet<RefreshToken> RefreshTokens => Set<RefreshToken>();
    public DbSet<Settlement> Settlements => Set<Settlement>();
    public DbSet<SupportTicket> SupportTickets => Set<SupportTicket>();
    public DbSet<SupportTicketMessage> SupportTicketMessages => Set<SupportTicketMessage>();
    public DbSet<SupportTicketMessagePhoto> SupportTicketMessagePhotos => Set<SupportTicketMessagePhoto>();
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

        // Tariff.Name uniqueness is checked case-insensitively in TariffService.EnsureUniqueNameAsync;
        // this index is the hard backstop behind that check (case-sensitive at the DB level).
        modelBuilder.Entity<Tariff>()
            .HasIndex(tariff => tariff.Name)
            .IsUnique();

        // Optimistic concurrency for invoice status transitions: every UPDATE carries the
        // loaded RowVersion in its WHERE clause, so a stale transition affects 0 rows and
        // surfaces as DbUpdateConcurrencyException instead of silently overwriting.
        modelBuilder.Entity<Invoice>()
            .Property(invoice => invoice.RowVersion)
            .IsRowVersion();

        // At most one reading per water meter per billing cycle; filtered so historical rows
        // with no BillingCycleId (BillingCycleId IS NULL) are excluded from the uniqueness check.
        modelBuilder.Entity<MeterReading>()
            .HasIndex(reading => new { reading.WaterMeterId, reading.BillingCycleId })
            .IsUnique()
            .HasFilter("[BillingCycleId] IS NOT NULL");

        // Photos have no independent lifecycle outside their report (unlike
        // WorkOrder/FaultStatusHistory rows, which stay Restrict so a report can't be
        // deleted while still referenced elsewhere) - deleting a FaultReport deletes its photos too.
        modelBuilder.Entity<FaultReportPhoto>()
            .HasOne(photo => photo.FaultReport)
            .WithMany(report => report.Photos)
            .HasForeignKey(photo => photo.FaultReportId)
            .OnDelete(DeleteBehavior.Cascade);

        // Support ticket thread cascades (same reasoning as FaultReportPhoto above): a message
        // and its photos have no independent lifecycle outside the ticket/message they belong to.
        // Deleting a ticket deletes its messages; deleting a message deletes its photos. The
        // message -> Sender (User) FK stays Restrict (from the loop above), so deleting a ticket
        // never cascades into the sending user.
        modelBuilder.Entity<SupportTicketMessage>()
            .HasOne(message => message.SupportTicket)
            .WithMany(ticket => ticket.Messages)
            .HasForeignKey(message => message.SupportTicketId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<SupportTicketMessagePhoto>()
            .HasOne(photo => photo.SupportTicketMessage)
            .WithMany(message => message.Photos)
            .HasForeignKey(photo => photo.SupportTicketMessageId)
            .OnDelete(DeleteBehavior.Cascade);

        // Security activity feed is queried per-user in reverse-chronological order
        // (e.g. "recent activity for user X"), so the index is composite rather than on UserId alone.
        modelBuilder.Entity<ActivityLog>()
            .HasIndex(log => new { log.UserId, log.CreatedAt });

        modelBuilder.Entity<ActivityLog>()
            .Property(log => log.EventType)
            .HasMaxLength(50);

        modelBuilder.Entity<ActivityLog>()
            .Property(log => log.Description)
            .HasMaxLength(500);

        modelBuilder.Entity<ActivityLog>()
            .Property(log => log.IpAddress)
            .HasMaxLength(45);

        CreateSeed(modelBuilder);
    }
}
