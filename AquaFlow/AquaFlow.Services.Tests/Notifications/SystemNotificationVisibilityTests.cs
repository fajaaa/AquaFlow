using AquaFlow.Model;
using AquaFlow.Model.Exceptions;
using AquaFlow.Model.Requests;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services.Database;
using FluentValidation;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace AquaFlow.Services.Tests.Notifications;

// Who can see a system notification (only its explicit recipients - never via the audience-based
// inbox backfill, not even an admin), how the admin /Notifications CRUD treats it (invisible,
// read-only, Direct audience rejected), and the push rules shared with admin announcements
// (failures swallowed, ReceivePushNotifications respected, deep-link payload, nothing pushed for a
// notification that was never saved). Users/tokens come from NotificationServiceTests' seed:
// Admin 1, Collector 2, Customer 3, OtherCustomer 4, OtherCollector 5, inactive Customer 6.
public class SystemNotificationVisibilityTests
{
    private const int AdminUserId = 1;
    private const int CollectorUserId = 2;
    private const int CustomerUserId = 3;
    private const int OtherCustomerUserId = 4;

    // ---- Inbox visibility (GET /UserNotifications/mine backfill) ----

    [Fact]
    public async Task AdminInboxBackfill_DoesNotPullInOtherUsersSystemNotifications()
    {
        await using var context = new AquaFlowDbContext(NotificationServiceTests.BuildOptions());
        NotificationServiceTests.SeedUsersAndLocations(context);
        var systemNotificationId = await StageAndSaveAsync(context, recipientUserId: CustomerUserId, actorUserId: CollectorUserId);
        var announcementId = await AddAnnouncementAsync(context, NotificationAudience.Customers);
        var service = NotificationServiceTests.CreateUserNotificationService(context);

        // What GET /UserNotifications/mine does for the admin (UserId pinned from the JWT).
        var page = await service.GetAllAsync(new UserNotificationSearchObject { UserId = AdminUserId, PageSize = 50 });

        var notificationIds = page.Items.Select(item => item.NotificationId).ToList();
        Assert.Contains(announcementId, notificationIds);
        Assert.DoesNotContain(systemNotificationId, notificationIds);
        Assert.False(await context.UserNotifications.AnyAsync(row =>
            row.UserId == AdminUserId && row.NotificationId == systemNotificationId));
    }

    [Fact]
    public async Task CustomerInboxBackfill_DoesNotPullInAnotherCustomersSystemNotification()
    {
        await using var context = new AquaFlowDbContext(NotificationServiceTests.BuildOptions());
        NotificationServiceTests.SeedUsersAndLocations(context);
        var systemNotificationId = await StageAndSaveAsync(context, recipientUserId: CustomerUserId, actorUserId: AdminUserId);
        var service = NotificationServiceTests.CreateUserNotificationService(context);

        var otherCustomerPage = await service.GetAllAsync(new UserNotificationSearchObject { UserId = OtherCustomerUserId, PageSize = 50 });
        var recipientPage = await service.GetAllAsync(new UserNotificationSearchObject { UserId = CustomerUserId, PageSize = 50 });

        Assert.DoesNotContain(otherCustomerPage.Items, item => item.NotificationId == systemNotificationId);
        var item = Assert.Single(recipientPage.Items, item => item.NotificationId == systemNotificationId);
        // The nested notification carries the deep-link fields for the FE.
        Assert.True(item.Notification!.IsSystem);
        Assert.Equal(RelatedEntityTypes.Invoice, item.Notification.RelatedEntityType);
        Assert.Equal(42, item.Notification.RelatedEntityId);
    }

    [Fact]
    public async Task GetRecipientUserIdsAsync_RejectsSystemNotification()
    {
        await using var context = new AquaFlowDbContext(NotificationServiceTests.BuildOptions());
        NotificationServiceTests.SeedUsersAndLocations(context);
        var systemNotificationId = await StageAndSaveAsync(context, recipientUserId: CustomerUserId, actorUserId: AdminUserId);
        var notification = await context.Notifications.SingleAsync(n => n.Id == systemNotificationId);

        await Assert.ThrowsAsync<ClientException>(() => new NotificationRecipientService(context).GetRecipientUserIdsAsync(notification));
    }

    // ---- Admin CRUD (/Notifications) ----

    [Fact]
    public async Task AdminGetAll_DoesNotListSystemNotifications()
    {
        await using var context = new AquaFlowDbContext(NotificationServiceTests.BuildOptions());
        NotificationServiceTests.SeedUsersAndLocations(context);
        var systemNotificationId = await StageAndSaveAsync(context, recipientUserId: CustomerUserId, actorUserId: AdminUserId);
        var announcementId = await AddAnnouncementAsync(context, NotificationAudience.All);
        var service = NotificationServiceTests.CreateNotificationService(context);

        var page = await service.GetAllAsync(new NotificationSearchObject { PageSize = 50, IncludeTotalCount = true });

        var item = Assert.Single(page.Items);
        Assert.Equal(announcementId, item.Id);
        Assert.Equal(1, page.TotalCount);
        Assert.DoesNotContain(page.Items, n => n.Id == systemNotificationId);
    }

    [Fact]
    public async Task AdminUpdatePatchDelete_OfSystemNotification_ThrowClientExceptionAndChangeNothing()
    {
        await using var context = new AquaFlowDbContext(NotificationServiceTests.BuildOptions());
        NotificationServiceTests.SeedUsersAndLocations(context);
        var id = await StageAndSaveAsync(context, recipientUserId: CustomerUserId, actorUserId: AdminUserId);
        var service = NotificationServiceTests.CreateNotificationService(context);

        await Assert.ThrowsAsync<ClientException>(() => service.UpdateAsync(id, new NotificationUpdateRequest
        {
            Title = "Izmijenjeno",
            Body = "Izmijenjeno",
            Type = NotificationType.Info,
            Audience = NotificationAudience.All,
            CreatedById = AdminUserId
        }));
        await Assert.ThrowsAsync<ClientException>(() => service.PatchAsync(id, new NotificationPatchRequest { Title = "Izmijenjeno" }));
        await Assert.ThrowsAsync<ClientException>(() => service.DeleteAsync(id));

        context.ChangeTracker.Clear();
        var notification = await context.Notifications.SingleAsync(n => n.Id == id);
        Assert.Equal("Racun izdan", notification.Title);
        Assert.Equal(NotificationAudience.Direct, notification.Audience);
        Assert.Equal(1, await context.UserNotifications.CountAsync(row => row.NotificationId == id));
    }

    [Theory]
    [InlineData("Direct")]
    [InlineData(" direct ")]
    public async Task AdminInsert_WithDirectAudience_IsRejectedByValidation(string audience)
    {
        await using var context = new AquaFlowDbContext(NotificationServiceTests.BuildOptions());
        NotificationServiceTests.SeedUsersAndLocations(context);
        var service = NotificationServiceTests.CreateNotificationService(context);

        await Assert.ThrowsAsync<ValidationException>(() => service.InsertAsync(new NotificationInsertRequest
        {
            Title = "Lazna sistemska",
            Body = "Pokusaj",
            Type = NotificationType.Info,
            Audience = audience,
            CreatedById = AdminUserId
        }));
        Assert.False(await context.Notifications.AnyAsync());
    }

    [Fact]
    public async Task AdminPatch_ToDirectAudience_IsRejectedByValidation()
    {
        await using var context = new AquaFlowDbContext(NotificationServiceTests.BuildOptions());
        NotificationServiceTests.SeedUsersAndLocations(context);
        var announcementId = await AddAnnouncementAsync(context, NotificationAudience.All);
        var service = NotificationServiceTests.CreateNotificationService(context);

        await Assert.ThrowsAsync<ValidationException>(() => service.PatchAsync(announcementId, new NotificationPatchRequest
        {
            Audience = NotificationAudience.Direct
        }));
    }

    // ---- Push ----

    [Fact]
    public async Task PushSenderThrows_TransitionAndNotificationAreStillSaved()
    {
        await using var context = FaultReportServiceTests.CreateContext();
        NotificationServiceTests.SeedUsersAndLocations(context);
        NotificationServiceTests.SeedDeviceTokens(context);
        SeedFaultReport(context);
        var pushSender = new FakePushNotificationSender { ExceptionToThrow = new InvalidOperationException("FCM unavailable") };
        var service = FaultReportServiceTests.CreateService(context, pushSender);

        var response = await service.AssignAsync(1, collectorId: 1, note: null, changedById: AdminUserId);

        Assert.Equal(FaultReportStateMachine.FaultReportStatus.Assigned, response.Status);
        context.ChangeTracker.Clear();
        Assert.Equal(FaultReportStateMachine.FaultReportStatus.Assigned, (await context.FaultReports.SingleAsync()).Status);
        await SystemNotificationEventTests.AssertSystemNotificationAsync(context, CustomerUserId, RelatedEntityTypes.FaultReport, 1);
        await SystemNotificationEventTests.AssertSystemNotificationAsync(context, CollectorUserId, RelatedEntityTypes.FaultReport, 1);
    }

    [Fact]
    public async Task ReceivePushNotificationsOff_InboxRowExistsButNoPushIsSent()
    {
        await using var context = FaultReportServiceTests.CreateContext();
        NotificationServiceTests.SeedUsersAndLocations(context);
        NotificationServiceTests.SeedDeviceTokens(context);
        SeedFaultReport(context);
        // The reporter opted out; the collector has no preference row at all (= default, push on).
        context.UserPreferences.Add(new UserPreference { Id = 1, UserId = CustomerUserId, ReceivePushNotifications = false });
        context.SaveChanges();
        var pushSender = new FakePushNotificationSender();
        var service = FaultReportServiceTests.CreateService(context, pushSender);

        await service.AssignAsync(1, collectorId: 1, note: null, changedById: AdminUserId);

        await SystemNotificationEventTests.AssertSystemNotificationAsync(context, CustomerUserId, RelatedEntityTypes.FaultReport, 1);
        var pushedTokens = pushSender.Calls.SelectMany(call => call.Tokens).ToList();
        Assert.DoesNotContain("token-customer", pushedTokens);
        Assert.Contains("token-collector", pushedTokens);
    }

    [Fact]
    public async Task SystemPush_CarriesTheDeepLinkTarget()
    {
        await using var context = FaultReportServiceTests.CreateContext();
        NotificationServiceTests.SeedUsersAndLocations(context);
        NotificationServiceTests.SeedDeviceTokens(context);
        SeedFaultReport(context);
        var pushSender = new FakePushNotificationSender();
        var service = FaultReportServiceTests.CreateService(context, pushSender);

        await service.AssignAsync(1, collectorId: 1, note: null, changedById: AdminUserId);

        var customerCall = Assert.Single(pushSender.Calls, call => call.Tokens.Contains("token-customer"));
        Assert.Equal(RelatedEntityTypes.FaultReport, customerCall.Data["relatedEntityType"]);
        Assert.Equal("1", customerCall.Data["relatedEntityId"]);
        Assert.Equal(NotificationType.Info, customerCall.Data["type"]);
        Assert.True(int.TryParse(customerCall.Data["notificationId"], out _));
    }

    [Fact]
    public async Task AdminAnnouncement_RespectsReceivePushNotificationsToo()
    {
        await using var context = new AquaFlowDbContext(NotificationServiceTests.BuildOptions());
        NotificationServiceTests.SeedUsersAndLocations(context);
        NotificationServiceTests.SeedDeviceTokens(context);
        context.UserPreferences.Add(new UserPreference { Id = 1, UserId = CustomerUserId, ReceivePushNotifications = false });
        context.SaveChanges();
        var pushSender = new FakePushNotificationSender();
        var service = NotificationServiceTests.CreateNotificationService(context, pushSender);

        var response = await service.InsertAsync(new NotificationInsertRequest
        {
            Title = "Planirani radovi",
            Body = "Sutra nema vode.",
            Type = NotificationType.PlannedWorks,
            Audience = NotificationAudience.Customers,
            CreatedById = AdminUserId
        });

        // Inbox rows for both customers, push only to the one who didn't opt out.
        Assert.True(await context.UserNotifications.AnyAsync(row => row.UserId == CustomerUserId && row.NotificationId == response.Id));
        var call = Assert.Single(pushSender.Calls);
        Assert.Equal(new[] { "token-other-customer" }, call.Tokens);
        Assert.False(call.Data.ContainsKey("relatedEntityType"));
    }

    [Fact]
    public async Task DispatchPendingPush_NeverPushesANotificationThatWasNotSaved()
    {
        await using var context = new AquaFlowDbContext(NotificationServiceTests.BuildOptions());
        NotificationServiceTests.SeedUsersAndLocations(context);
        NotificationServiceTests.SeedDeviceTokens(context);
        var pushSender = new FakePushNotificationSender();
        var systemNotifications = TestSystemNotifications.Create(context, pushSender);

        // Staged, but the business SaveChanges never happened (e.g. it failed and the caller moved on).
        systemNotifications.Stage(Message(), new[] { CustomerUserId }, AdminUserId);
        await systemNotifications.DispatchPendingPushAsync();
        // A later, unrelated save in the same scope must not persist it after the fact either.
        await context.SaveChangesAsync();

        Assert.Empty(pushSender.Calls);
        Assert.False(await context.Notifications.AnyAsync());
        Assert.False(await context.UserNotifications.AnyAsync());
    }

    // ---- Helpers ----

    private static SystemNotificationMessage Message() =>
        new("Racun izdan", "Izdan je novi racun.", NotificationType.Billing, RelatedEntityTypes.Invoice, 42);

    private static async Task<int> StageAndSaveAsync(AquaFlowDbContext context, int recipientUserId, int actorUserId)
    {
        var systemNotifications = TestSystemNotifications.Create(context);
        systemNotifications.Stage(Message(), new[] { recipientUserId }, actorUserId);
        await context.SaveChangesAsync();
        await systemNotifications.DispatchPendingPushAsync();

        return await context.Notifications.Where(n => n.IsSystem).Select(n => n.Id).SingleAsync();
    }

    private static async Task<int> AddAnnouncementAsync(AquaFlowDbContext context, string audience)
    {
        var announcement = new Notification
        {
            Title = "Obavijest",
            Body = "Sadrzaj obavijesti.",
            Type = NotificationType.Info,
            Audience = audience,
            CreatedById = AdminUserId,
            CreatedAt = DateTime.UtcNow
        };
        context.Notifications.Add(announcement);
        await context.SaveChangesAsync();
        return announcement.Id;
    }

    // Reported by Customer (user 3), still New - assigning it to CollectorProfile 1 (user 2)
    // notifies both of them.
    private static void SeedFaultReport(AquaFlowDbContext context)
    {
        context.Settlements.Add(new Settlement { Id = 10, Name = "Bjelave", MunicipalityId = 1, PostalCode = "71000" });
        context.FaultReports.Add(new FaultReport
        {
            Id = 1,
            ReportedById = CustomerUserId,
            CustomerId = 1,
            SettlementId = 10,
            Title = "Curenje vode",
            Description = "Voda curi ispred kuce.",
            Status = FaultReportStateMachine.FaultReportStatus.New
        });
        context.SaveChanges();
    }
}
