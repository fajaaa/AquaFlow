using AquaFlow.Model;
using AquaFlow.Model.Requests;
using AquaFlow.Services.Database;
using AquaFlow.Services.FaultReportStateMachine;
using AquaFlow.Services.Payments;
using AquaFlow.Services.Tests.MeterReadings;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace AquaFlow.Services.Tests.Notifications;

// One test per business event that must create a system notification for "the other side": the
// right user gets a UserNotification whose Notification is IsSystem/Direct with the right
// RelatedEntityType/RelatedEntityId, and the actor never gets one. Each test drives the real service
// (and its real state machine) built by the module's own test factory, so the notification is
// produced by exactly the code path production uses.
public class SystemNotificationEventTests
{
    private const int AdminUserId = 1;
    private const int OtherAdminUserId = 2;
    private const int CustomerUserId = 3;
    private const int OtherCustomerUserId = 4;
    private const int CollectorUserId = 5;
    private const int OtherCollectorUserId = 6;
    private const int InactiveAdminUserId = 7;

    private const int CustomerProfileId = 1;
    private const int OtherCustomerProfileId = 2;
    private const int CollectorProfileId = 1;
    private const int OtherCollectorProfileId = 2;

    // ---- WaterMeterRequest ----

    [Fact]
    public async Task WaterMeterRequest_CreateForUser_NotifiesManageStaffButNotTheRequester()
    {
        await using var context = WaterMeterRequestServiceTests.CreateContext();
        SeedPeople(context, "WaterMeterRequests.Manage");
        var service = WaterMeterRequestServiceTests.CreateService(context);

        var response = await service.CreateForUserAsync(CustomerUserId, new WaterMeterRequestInsertRequest
        {
            SettlementId = 1,
            Street = "Zmaja od Bosne",
            HouseNumber = "12A"
        });

        var notification = await AssertSystemNotificationAsync(context, AdminUserId, RelatedEntityTypes.WaterMeterRequest, response.Id);
        Assert.Equal(CustomerUserId, notification.CreatedById);
        await AssertSystemNotificationAsync(context, OtherAdminUserId, RelatedEntityTypes.WaterMeterRequest, response.Id);
        await AssertNoNotificationAsync(context, CustomerUserId);
        await AssertNoNotificationAsync(context, InactiveAdminUserId);
        await AssertNoNotificationAsync(context, CollectorUserId);
    }

    [Fact]
    public async Task WaterMeterRequest_Assign_NotifiesRequesterAndAssignedCollector()
    {
        await using var context = WaterMeterRequestServiceTests.CreateContext();
        SeedPeople(context);
        SeedWaterMeterRequest(context, WaterMeterRequestStatus.Pending);
        var service = WaterMeterRequestServiceTests.CreateService(context);

        await service.AssignAsync(1, CollectorProfileId, changedById: AdminUserId);

        await AssertSystemNotificationAsync(context, CustomerUserId, RelatedEntityTypes.WaterMeterRequest, 1);
        await AssertSystemNotificationAsync(context, CollectorUserId, RelatedEntityTypes.WaterMeterRequest, 1);
        await AssertNoNotificationAsync(context, AdminUserId);
        await AssertNoNotificationAsync(context, OtherCollectorUserId);
        await AssertNoNotificationAsync(context, OtherCustomerUserId);
    }

    [Fact]
    public async Task WaterMeterRequest_Reject_NotifiesRequesterWithReason()
    {
        await using var context = WaterMeterRequestServiceTests.CreateContext();
        SeedPeople(context);
        SeedWaterMeterRequest(context, WaterMeterRequestStatus.Pending);
        var service = WaterMeterRequestServiceTests.CreateService(context);

        await service.RejectAsync(1, "Adresa nije u zoni pokrivanja.", changedById: AdminUserId);

        var notification = await AssertSystemNotificationAsync(context, CustomerUserId, RelatedEntityTypes.WaterMeterRequest, 1);
        Assert.Equal(NotificationType.Warning, notification.Type);
        Assert.Contains("Adresa nije u zoni pokrivanja.", notification.Body);
        await AssertNoNotificationAsync(context, AdminUserId);
    }

    [Fact]
    public async Task WaterMeterRequest_Register_NotifiesRequesterWithSerialNumberButNotTheCollector()
    {
        await using var context = WaterMeterRequestServiceTests.CreateContext();
        SeedPeople(context);
        SeedWaterMeterRequest(context, WaterMeterRequestStatus.Assigned, assignedCollectorId: CollectorProfileId);
        var service = WaterMeterRequestServiceTests.CreateService(context);

        await service.RegisterAsync(1, new WaterMeterInsertRequest
        {
            SerialNumber = "WM-2026-0042",
            SettlementId = 1,
            Street = "Zmaja od Bosne",
            HouseNumber = "12A",
            Status = "Active",
            InitialReading = 0
        }, changedById: CollectorUserId);

        var notification = await AssertSystemNotificationAsync(context, CustomerUserId, RelatedEntityTypes.WaterMeterRequest, 1);
        Assert.Contains("WM-2026-0042", notification.Body);
        await AssertNoNotificationAsync(context, CollectorUserId);
    }

    [Fact]
    public async Task WaterMeterRequest_CancelByRequester_NotifiesNobody()
    {
        await using var context = WaterMeterRequestServiceTests.CreateContext();
        SeedPeople(context, "WaterMeterRequests.Manage");
        SeedWaterMeterRequest(context, WaterMeterRequestStatus.Pending);
        var service = WaterMeterRequestServiceTests.CreateService(context);

        await service.CancelAsync(1, changedById: CustomerUserId);

        Assert.False(await context.Notifications.AnyAsync());
    }

    // ---- FaultReport ----

    [Fact]
    public async Task FaultReport_Create_NotifiesManageStaffButNotTheReporter()
    {
        await using var context = FaultReportServiceTests.CreateContext();
        SeedPeople(context, "FaultReports.Manage");
        var service = FaultReportServiceTests.CreateService(context);

        var response = await service.CreateAsync(new FaultReportInsertRequest
        {
            ReportedById = CustomerUserId,
            CustomerId = CustomerProfileId,
            SettlementId = 1,
            Title = "Curenje vode",
            Description = "Voda curi ispred kuce.",
            Status = FaultReportStatus.New
        }, actorUserId: CustomerUserId);

        await AssertSystemNotificationAsync(context, AdminUserId, RelatedEntityTypes.FaultReport, response.Id);
        await AssertSystemNotificationAsync(context, OtherAdminUserId, RelatedEntityTypes.FaultReport, response.Id);
        await AssertNoNotificationAsync(context, CustomerUserId);
        await AssertNoNotificationAsync(context, InactiveAdminUserId);
    }

    [Fact]
    public async Task FaultReport_CreateByAdminOnBehalfOfCustomer_DoesNotNotifyTheActingAdmin()
    {
        await using var context = FaultReportServiceTests.CreateContext();
        SeedPeople(context, "FaultReports.Manage");
        var service = FaultReportServiceTests.CreateService(context);

        var response = await service.CreateAsync(new FaultReportInsertRequest
        {
            ReportedById = CustomerUserId,
            SettlementId = 1,
            Title = "Curenje vode",
            Description = "Prijavljeno telefonom.",
            Status = FaultReportStatus.New
        }, actorUserId: AdminUserId);

        await AssertNoNotificationAsync(context, AdminUserId);
        await AssertSystemNotificationAsync(context, OtherAdminUserId, RelatedEntityTypes.FaultReport, response.Id);
    }

    [Fact]
    public async Task FaultReport_Assign_NotifiesReporterAndAssignedCollector()
    {
        await using var context = FaultReportServiceTests.CreateContext();
        SeedPeople(context);
        SeedFaultReport(context, FaultReportStatus.New);
        var service = FaultReportServiceTests.CreateService(context);

        await service.AssignAsync(1, CollectorProfileId, note: null, changedById: AdminUserId);

        await AssertSystemNotificationAsync(context, CustomerUserId, RelatedEntityTypes.FaultReport, 1);
        await AssertSystemNotificationAsync(context, CollectorUserId, RelatedEntityTypes.FaultReport, 1);
        await AssertNoNotificationAsync(context, AdminUserId);
        await AssertNoNotificationAsync(context, OtherCollectorUserId);
    }

    [Fact]
    public async Task FaultReport_Reassign_AlsoNotifiesThePreviousCollector()
    {
        await using var context = FaultReportServiceTests.CreateContext();
        SeedPeople(context);
        SeedFaultReport(context, FaultReportStatus.Assigned, assignedCollectorId: CollectorProfileId);
        var service = FaultReportServiceTests.CreateService(context);

        await service.AssignAsync(1, OtherCollectorProfileId, note: "Bolja ruta.", changedById: AdminUserId);

        var previous = await AssertSystemNotificationAsync(context, CollectorUserId, RelatedEntityTypes.FaultReport, 1);
        Assert.Contains("preraspodijeljena", previous.Title);
        await AssertSystemNotificationAsync(context, OtherCollectorUserId, RelatedEntityTypes.FaultReport, 1);
        await AssertSystemNotificationAsync(context, CustomerUserId, RelatedEntityTypes.FaultReport, 1);
        await AssertNoNotificationAsync(context, AdminUserId);
    }

    [Fact]
    public async Task FaultReport_Start_NotifiesReporterButNotTheCollector()
    {
        await using var context = FaultReportServiceTests.CreateContext();
        SeedPeople(context);
        SeedFaultReport(context, FaultReportStatus.Assigned, assignedCollectorId: CollectorProfileId);
        var service = FaultReportServiceTests.CreateService(context);

        await service.StartAsync(1, changedById: CollectorUserId);

        await AssertSystemNotificationAsync(context, CustomerUserId, RelatedEntityTypes.FaultReport, 1);
        await AssertNoNotificationAsync(context, CollectorUserId);
    }

    [Fact]
    public async Task FaultReport_Resolve_NotifiesReporterButNotTheCollector()
    {
        await using var context = FaultReportServiceTests.CreateContext();
        SeedPeople(context);
        SeedFaultReport(context, FaultReportStatus.InProgress, assignedCollectorId: CollectorProfileId);
        var service = FaultReportServiceTests.CreateService(context);

        await service.ResolveAsync(1, changedById: CollectorUserId);

        var notification = await AssertSystemNotificationAsync(context, CustomerUserId, RelatedEntityTypes.FaultReport, 1);
        Assert.Contains("riješena", notification.Title);
        await AssertNoNotificationAsync(context, CollectorUserId);
    }

    // ---- Invoice / Payment ----
    // InvoiceCheckoutTests.SeedInvoice / MeterReadingServiceTests.SeedTestData seed the customer as
    // User 1 (CustomerProfile 1); the admin/collector actors below are other ids.

    [Fact]
    public async Task Invoice_CreatedFromMeterReading_NotifiesCustomerButNotTheCollector()
    {
        await using var context = MeterReadingServiceTests.CreateContext();
        MeterReadingServiceTests.SeedTestData(context);
        var service = MeterReadingServiceTests.CreateService(context);

        var response = await service.CreateForCollectorAsync(callerUserId: 3, new MeterReadingCollectorEntryRequest
        {
            WaterMeterId = 1,
            ReadingValue = 50,
            TariffId = 1
        });

        var notification = await AssertSystemNotificationAsync(context, 1, RelatedEntityTypes.Invoice, response.InvoiceId!.Value);
        Assert.Equal(NotificationType.Billing, notification.Type);
        Assert.Contains(response.InvoiceNumber!, notification.Title);
        await AssertNoNotificationAsync(context, 3);
    }

    [Fact]
    public async Task Invoice_ZeroConsumptionReading_CreatesNoInvoiceAndNoNotification()
    {
        await using var context = MeterReadingServiceTests.CreateContext();
        MeterReadingServiceTests.SeedTestData(context);
        var service = MeterReadingServiceTests.CreateService(context);

        var response = await service.CreateForCollectorAsync(callerUserId: 3, new MeterReadingCollectorEntryRequest
        {
            WaterMeterId = 1,
            ReadingValue = 0,
            TariffId = 1
        });

        Assert.Null(response.InvoiceId);
        Assert.False(await context.Notifications.AnyAsync());
    }

    [Fact]
    public async Task Invoice_ManualPaymentRecorded_NotifiesCustomerButNotTheAdmin()
    {
        await using var context = InvoiceCheckoutTests.CreateContext();
        InvoiceCheckoutTests.SeedInvoice(context, id: 1, totalAmount: 50m, status: InvoiceStatus.Issued);
        var service = InvoiceCheckoutTests.CreateService(context, new FakePaymentProvider());

        await service.RecordPaymentAsync(1, changedById: 99);

        var notification = await AssertSystemNotificationAsync(context, 1, RelatedEntityTypes.Invoice, 1);
        Assert.Equal(NotificationType.Billing, notification.Type);
        Assert.Contains("plaćen", notification.Title);
        await AssertNoNotificationAsync(context, 99);
    }

    [Fact]
    public async Task Invoice_StripeWebhookSucceededTwice_NotifiesCustomerExactlyOnce()
    {
        await using var context = InvoiceCheckoutTests.CreateContext();
        InvoiceCheckoutTests.SeedInvoice(context, id: 1, totalAmount: 50m, status: InvoiceStatus.Issued);
        InvoiceCheckoutTests.SeedPayment(context, id: 1, amount: 50m, status: PaymentStatus.Pending, transactionId: "pi_1");
        var service = InvoiceCheckoutTests.CreateService(context, new FakePaymentProvider());

        await service.ConfirmPaymentAsync(PaymentProvider.Stripe, "pi_1", PaymentConfirmationOutcome.Succeeded);
        // Stripe retries a delivery it didn't see acknowledged - the second call is the idempotent no-op.
        await service.ConfirmPaymentAsync(PaymentProvider.Stripe, "pi_1", PaymentConfirmationOutcome.Succeeded);

        // No human actor: the history row is attributed to the paying customer, who is still told.
        await AssertSystemNotificationAsync(context, 1, RelatedEntityTypes.Invoice, 1);
        Assert.Equal(1, await context.Notifications.CountAsync());
    }

    [Fact]
    public async Task Invoice_CheckoutFindsAlreadySucceededAttempt_ThenLateWebhook_NotifiesExactlyOnce()
    {
        await using var context = InvoiceCheckoutTests.CreateContext();
        InvoiceCheckoutTests.SeedInvoice(context, id: 1, totalAmount: 50m, status: InvoiceStatus.Issued);
        InvoiceCheckoutTests.SeedPayment(context, id: 1, amount: 50m, status: PaymentStatus.Pending, transactionId: "pi_1");
        var provider = new FakePaymentProvider();
        provider.ResumeStates["pi_1"] = PaymentAttemptState.Succeeded;
        var service = InvoiceCheckoutTests.CreateService(context, provider);

        var session = await service.CheckoutAsync(1, idempotencyKey: null);
        await service.ConfirmPaymentAsync(PaymentProvider.Stripe, "pi_1", PaymentConfirmationOutcome.Succeeded);

        Assert.True(session.AlreadySucceeded);
        await AssertSystemNotificationAsync(context, 1, RelatedEntityTypes.Invoice, 1);
        Assert.Equal(1, await context.Notifications.CountAsync());
    }

    [Fact]
    public async Task Invoice_Cancel_NotifiesCustomerButNotTheAdmin()
    {
        await using var context = InvoiceCheckoutTests.CreateContext();
        InvoiceCheckoutTests.SeedInvoice(context, id: 1, totalAmount: 50m, status: InvoiceStatus.Issued);
        var service = InvoiceCheckoutTests.CreateService(context, new FakePaymentProvider());

        await service.CancelAsync(1, changedById: 99);

        var notification = await AssertSystemNotificationAsync(context, 1, RelatedEntityTypes.Invoice, 1);
        Assert.Contains("storniran", notification.Title);
        await AssertNoNotificationAsync(context, 99);
    }

    // ---- SupportTicket ----

    [Fact]
    public async Task SupportTicket_Create_NotifiesManageStaffButNotTheCustomer()
    {
        await using var context = SupportTicketServiceTests.CreateContext();
        SeedPeople(context, "SupportTickets.Manage");
        var service = SupportTicketServiceTests.CreateService(context);

        var ticket = await service.CreateForUserAsync(CustomerUserId, "Pogresan racun", "Racun je previsok.", Array.Empty<SupportTicketPhotoUpload>());

        await AssertSystemNotificationAsync(context, AdminUserId, RelatedEntityTypes.SupportTicket, ticket.Id);
        await AssertSystemNotificationAsync(context, OtherAdminUserId, RelatedEntityTypes.SupportTicket, ticket.Id);
        await AssertNoNotificationAsync(context, CustomerUserId);
    }

    [Fact]
    public async Task SupportTicket_CustomerMessage_NotifiesManageStaff()
    {
        await using var context = SupportTicketServiceTests.CreateContext();
        SeedPeople(context, "SupportTickets.Manage");
        SeedSupportTicket(context, SupportTicketStatus.Open);
        var service = SupportTicketServiceTests.CreateService(context);

        await service.AddMessageAsync(1, CustomerUserId, isFromStaff: false, "Ima li novosti?", Array.Empty<SupportTicketPhotoUpload>());

        await AssertSystemNotificationAsync(context, AdminUserId, RelatedEntityTypes.SupportTicket, 1);
        await AssertNoNotificationAsync(context, CustomerUserId);
    }

    [Fact]
    public async Task SupportTicket_StaffMessage_NotifiesTicketOwnerButNotTheStaffMember()
    {
        await using var context = SupportTicketServiceTests.CreateContext();
        SeedPeople(context, "SupportTickets.Manage");
        SeedSupportTicket(context, SupportTicketStatus.Open);
        var service = SupportTicketServiceTests.CreateService(context);

        await service.AddMessageAsync(1, AdminUserId, isFromStaff: true, "Provjeravamo.", Array.Empty<SupportTicketPhotoUpload>());

        await AssertSystemNotificationAsync(context, CustomerUserId, RelatedEntityTypes.SupportTicket, 1);
        await AssertNoNotificationAsync(context, AdminUserId);
        await AssertNoNotificationAsync(context, OtherAdminUserId);
        await AssertNoNotificationAsync(context, OtherCustomerUserId);
    }

    [Fact]
    public async Task SupportTicket_CloseAndReopen_EachNotifyTheOwner()
    {
        await using var context = SupportTicketServiceTests.CreateContext();
        SeedPeople(context, "SupportTickets.Manage");
        SeedSupportTicket(context, SupportTicketStatus.Open);
        var service = SupportTicketServiceTests.CreateService(context);

        await service.CloseAsync(1, actorUserId: AdminUserId);
        await service.ReopenAsync(1, actorUserId: AdminUserId);

        var titles = await context.UserNotifications
            .Where(row => row.UserId == CustomerUserId)
            .Select(row => row.Notification!.Title)
            .ToListAsync();
        Assert.Equal(2, titles.Count);
        Assert.Contains(titles, title => title.Contains("zatvoren"));
        Assert.Contains(titles, title => title.Contains("ponovo otvoren"));
        await AssertNoNotificationAsync(context, AdminUserId);
    }

    // ---- Seeding / assertions ----

    // Roles Admin(1)/Collector(2)/Customer(3); the Admin role holds the given Manage permission codes.
    // Two active admins (both should receive staff notifications), one inactive admin (never), two
    // customers and two collectors (so "the other one didn't get it" can be asserted), settlement 1.
    private static void SeedPeople(AquaFlowDbContext context, params string[] adminPermissionCodes)
    {
        context.UserRoles.AddRange(
            new UserRole { Id = 1, Name = "Admin" },
            new UserRole { Id = 2, Name = "Collector" },
            new UserRole { Id = 3, Name = "Customer" });

        for (var i = 0; i < adminPermissionCodes.Length; i++)
        {
            context.Permissions.Add(new Permission { Id = i + 1, Code = adminPermissionCodes[i], Name = adminPermissionCodes[i], IsActive = true });
            context.UserRolePermissions.Add(new UserRolePermission { Id = i + 1, UserRoleId = 1, PermissionId = i + 1 });
        }

        context.Users.AddRange(
            CreateUser(AdminUserId, 1),
            CreateUser(OtherAdminUserId, 1),
            CreateUser(CustomerUserId, 3),
            CreateUser(OtherCustomerUserId, 3),
            CreateUser(CollectorUserId, 2),
            CreateUser(OtherCollectorUserId, 2),
            CreateUser(InactiveAdminUserId, 1, isActive: false));

        context.Settlements.Add(new Settlement { Id = 1, Name = "Bjelave", MunicipalityId = 1, PostalCode = "71000" });

        context.CustomerProfiles.AddRange(
            new CustomerProfile { Id = CustomerProfileId, UserId = CustomerUserId, FirstName = "Amina", LastName = "Amidzic", CustomerCode = "CUS-0001", SettlementId = 1 },
            new CustomerProfile { Id = OtherCustomerProfileId, UserId = OtherCustomerUserId, FirstName = "Edin", LastName = "Hodzic", CustomerCode = "CUS-0002", SettlementId = 1 });

        context.CollectorProfiles.AddRange(
            new CollectorProfile { Id = CollectorProfileId, UserId = CollectorUserId, EmployeeCode = "COL-0001" },
            new CollectorProfile { Id = OtherCollectorProfileId, UserId = OtherCollectorUserId, EmployeeCode = "COL-0002" });

        context.SaveChanges();
    }

    private static void SeedWaterMeterRequest(AquaFlowDbContext context, string status, int? assignedCollectorId = null)
    {
        context.WaterMeterRequests.Add(new WaterMeterRequest
        {
            Id = 1,
            CustomerId = CustomerProfileId,
            Status = status,
            AssignedCollectorId = assignedCollectorId,
            SettlementId = 1,
            Street = "Zmaja od Bosne",
            HouseNumber = "12A"
        });
        context.SaveChanges();
    }

    private static void SeedFaultReport(AquaFlowDbContext context, string status, int? assignedCollectorId = null)
    {
        context.FaultReports.Add(new FaultReport
        {
            Id = 1,
            ReportedById = CustomerUserId,
            CustomerId = CustomerProfileId,
            SettlementId = 1,
            Title = "Curenje vode",
            Description = "Voda curi ispred kuce.",
            Status = status,
            AssignedCollectorId = assignedCollectorId
        });
        context.SaveChanges();
    }

    private static void SeedSupportTicket(AquaFlowDbContext context, string status)
    {
        context.SupportTickets.Add(new SupportTicket
        {
            Id = 1,
            CustomerId = CustomerProfileId,
            Subject = "Pogresan racun",
            Status = status,
            LastMessageAt = DateTime.UtcNow
        });
        context.SaveChanges();
    }

    private static User CreateUser(int id, int roleId, bool isActive = true) => new()
    {
        Id = id,
        Email = $"user{id}@aquaflow.ba",
        PasswordHash = "hash",
        PasswordSalt = "salt",
        UserRoleId = roleId,
        IsActive = isActive
    };

    // The recipient has exactly one inbox row for a notification about this record, and that
    // notification is a system one (IsSystem, Direct audience) pointing at the record.
    internal static async Task<Notification> AssertSystemNotificationAsync(AquaFlowDbContext context, int recipientUserId, string relatedEntityType, int relatedEntityId)
    {
        var rows = await context.UserNotifications
            .Include(row => row.Notification)
            .Where(row => row.UserId == recipientUserId
                && row.Notification!.RelatedEntityType == relatedEntityType
                && row.Notification.RelatedEntityId == relatedEntityId)
            .ToListAsync();

        var row = Assert.Single(rows);
        Assert.True(row.Notification!.IsSystem);
        Assert.Equal(NotificationAudience.Direct, row.Notification.Audience);
        Assert.Null(row.ReadAt);
        return row.Notification;
    }

    internal static async Task AssertNoNotificationAsync(AquaFlowDbContext context, int userId)
    {
        Assert.False(await context.UserNotifications.AnyAsync(row => row.UserId == userId));
    }
}
