using AquaFlow.Common.Services.PushNotificationService;
using AquaFlow.Model.Requests;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services.Database;
using AquaFlow.Services.Validators;
using FluentValidation;
using Mapster;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Microsoft.Extensions.Logging.Abstractions;
using Xunit;

namespace AquaFlow.Services.Tests.Notifications;

public class NotificationServiceTests
{
    private const int AdminUserId = 1;
    private const int CollectorUserId = 2;
    private const int CustomerUserId = 3;
    private const int OtherCustomerUserId = 4;
    private const int OtherCollectorUserId = 5;
    private const int InactiveCustomerUserId = 6;

    [Fact]
    public async Task InsertAsync_AllAudience_CreatesInboxRowsForActiveUsers()
    {
        var options = BuildOptions();
        await using var context = new AquaFlowDbContext(options);
        SeedUsersAndLocations(context);

        var service = CreateNotificationService(context);
        var response = await service.InsertAsync(new NotificationInsertRequest
        {
            Title = "Nova obavijest",
            Body = "Sadrzaj obavijesti",
            Type = "Info",
            Audience = "All",
            CreatedById = AdminUserId
        });

        var userIds = await context.UserNotifications
            .Where(userNotification => userNotification.NotificationId == response.Id)
            .Select(userNotification => userNotification.UserId)
            .OrderBy(userId => userId)
            .ToListAsync();

        Assert.Equal(
            new[] { AdminUserId, CollectorUserId, CustomerUserId, OtherCustomerUserId, OtherCollectorUserId },
            userIds);
        Assert.DoesNotContain(InactiveCustomerUserId, userIds);
    }

    [Fact]
    public async Task InsertAsync_SettlementAudience_CreatesInboxRowsForSettlementCustomersAndCollectors()
    {
        var options = BuildOptions();
        await using var context = new AquaFlowDbContext(options);
        SeedUsersAndLocations(context);

        var service = CreateNotificationService(context);
        var response = await service.InsertAsync(new NotificationInsertRequest
        {
            Title = "Radovi u naselju",
            Body = "Planirani radovi na mrezi.",
            Type = "PlannedWorks",
            Audience = "Settlement",
            SettlementId = 10,
            CreatedById = AdminUserId
        });

        var userIds = await context.UserNotifications
            .Where(userNotification => userNotification.NotificationId == response.Id)
            .Select(userNotification => userNotification.UserId)
            .OrderBy(userId => userId)
            .ToListAsync();

        Assert.Equal(new[] { CollectorUserId, CustomerUserId }, userIds);
    }

    [Fact]
    public async Task UpdateAsync_NarrowsAudienceToSettlement_RemovesInboxRowsForUsersOutsideNewAudience()
    {
        var options = BuildOptions();
        await using var context = new AquaFlowDbContext(options);
        SeedUsersAndLocations(context);

        var service = CreateNotificationService(context);
        var response = await service.InsertAsync(new NotificationInsertRequest
        {
            Title = "Nova obavijest",
            Body = "Sadrzaj obavijesti",
            Type = "Info",
            Audience = "All",
            CreatedById = AdminUserId
        });

        var initialUserIds = await context.UserNotifications
            .Where(userNotification => userNotification.NotificationId == response.Id)
            .Select(userNotification => userNotification.UserId)
            .OrderBy(userId => userId)
            .ToListAsync();
        Assert.Equal(
            new[] { AdminUserId, CollectorUserId, CustomerUserId, OtherCustomerUserId, OtherCollectorUserId },
            initialUserIds);

        await service.UpdateAsync(response.Id, new NotificationUpdateRequest
        {
            Title = "Nova obavijest",
            Body = "Osjetljiv sadrzaj samo za naselje 20",
            Type = "Info",
            Audience = "Settlement",
            SettlementId = 20,
            CreatedById = AdminUserId
        });

        var userIdsAfterUpdate = await context.UserNotifications
            .Where(userNotification => userNotification.NotificationId == response.Id)
            .Select(userNotification => userNotification.UserId)
            .OrderBy(userId => userId)
            .ToListAsync();

        // Settlement 20 covers OtherCustomerUserId (CustomerProfile SettlementId=20) and
        // OtherCollectorUserId (CollectorProfile AssignedAreaId=20) only.
        Assert.Equal(new[] { OtherCustomerUserId, OtherCollectorUserId }.OrderBy(id => id), userIdsAfterUpdate);
        Assert.DoesNotContain(AdminUserId, userIdsAfterUpdate);
        Assert.DoesNotContain(CollectorUserId, userIdsAfterUpdate);
        Assert.DoesNotContain(CustomerUserId, userIdsAfterUpdate);
    }

    [Fact]
    public async Task GetAllAsync_ForUser_BackfillsMissingInboxRowsForVisibleNotifications()
    {
        var options = BuildOptions();
        await using var context = new AquaFlowDbContext(options);
        SeedUsersAndLocations(context);
        context.Notifications.Add(new Notification
        {
            Id = 900,
            Title = "Racun spreman",
            Body = "Novi racun je dostupan.",
            Type = "Billing",
            Audience = "Customers",
            CreatedById = AdminUserId,
            CreatedAt = DateTime.UtcNow
        });
        await context.SaveChangesAsync();

        var service = CreateUserNotificationService(context);
        var page = await service.GetAllAsync(new UserNotificationSearchObject
        {
            UserId = CustomerUserId,
            Page = 1,
            PageSize = 10,
            IncludeTotalCount = true
        });

        Assert.Single(page.Items);
        Assert.Equal(1, page.TotalCount);
        Assert.True(await context.UserNotifications.AnyAsync(userNotification =>
            userNotification.UserId == CustomerUserId &&
            userNotification.NotificationId == 900));
        Assert.False(await context.UserNotifications.AnyAsync(userNotification =>
            userNotification.UserId == CollectorUserId &&
            userNotification.NotificationId == 900));
    }

    [Fact]
    public async Task GetAllAsync_ForUser_BackfilledRowSortsByNotificationDateNotBackfillTime()
    {
        var options = BuildOptions();
        await using var context = new AquaFlowDbContext(options);
        SeedUsersAndLocations(context);

        var oldNotificationDate = DateTime.UtcNow.AddDays(-30);
        context.Notifications.Add(new Notification
        {
            Id = 900,
            Title = "Stara obavijest",
            Body = "Obavijest objavljena prije mjesec dana.",
            Type = "Info",
            Audience = "Customers",
            CreatedById = AdminUserId,
            CreatedAt = oldNotificationDate
        });
        await context.SaveChangesAsync();

        var service = CreateUserNotificationService(context);

        // First load happens long after the notification was published, so its inbox
        // row for this user only gets created now (the backfill path), not at insert time.
        await service.GetAllAsync(new UserNotificationSearchObject
        {
            UserId = CustomerUserId,
            Page = 1,
            PageSize = 10
        });

        var inboxRow = await context.UserNotifications.SingleAsync(userNotification =>
            userNotification.UserId == CustomerUserId &&
            userNotification.NotificationId == 900);

        Assert.Equal(oldNotificationDate, inboxRow.CreatedAt);
    }

    [Fact]
    public async Task GetAllAsync_ForAdmin_BackfillsInboxRowsForEveryAudience()
    {
        var options = BuildOptions();
        await using var context = new AquaFlowDbContext(options);
        SeedUsersAndLocations(context);
        context.Notifications.AddRange(
            new Notification
            {
                Id = 900,
                Title = "Racun spreman",
                Body = "Novi racun je dostupan.",
                Type = "Billing",
                Audience = "Customers",
                CreatedById = AdminUserId,
                CreatedAt = DateTime.UtcNow
            },
            new Notification
            {
                Id = 901,
                Title = "Raspored obilaska",
                Body = "Novi raspored za inkasante.",
                Type = "Info",
                Audience = "Collectors",
                CreatedById = AdminUserId,
                CreatedAt = DateTime.UtcNow
            },
            new Notification
            {
                Id = 902,
                Title = "Radovi u naselju",
                Body = "Planirani radovi na mrezi.",
                Type = "PlannedWorks",
                Audience = "Settlement",
                SettlementId = 10,
                CreatedById = AdminUserId,
                CreatedAt = DateTime.UtcNow
            });
        await context.SaveChangesAsync();

        var service = CreateUserNotificationService(context);
        var page = await service.GetAllAsync(new UserNotificationSearchObject
        {
            UserId = AdminUserId,
            Page = 1,
            PageSize = 10,
            IncludeTotalCount = true
        });

        Assert.Equal(3, page.TotalCount);
        var notificationIds = page.Items.Select(item => item.NotificationId).OrderBy(id => id);
        Assert.Equal(new[] { 900, 901, 902 }, notificationIds);
    }

    [Fact]
    public async Task GetAllAsync_ForUser_FiltersByNotificationType()
    {
        var options = BuildOptions();
        await using var context = new AquaFlowDbContext(options);
        SeedUsersAndLocations(context);
        context.Notifications.AddRange(
            new Notification
            {
                Id = 900,
                Title = "Opsta obavijest",
                Body = "Sadrzaj obavijesti.",
                Type = "Info",
                Audience = "Customers",
                CreatedById = AdminUserId,
                CreatedAt = DateTime.UtcNow
            },
            new Notification
            {
                Id = 901,
                Title = "Racun spreman",
                Body = "Novi racun je dostupan.",
                Type = "Billing",
                Audience = "Customers",
                CreatedById = AdminUserId,
                CreatedAt = DateTime.UtcNow
            });
        await context.SaveChangesAsync();

        var service = CreateUserNotificationService(context);
        var page = await service.GetAllAsync(new UserNotificationSearchObject
        {
            UserId = CustomerUserId,
            Type = "Billing",
            Page = 1,
            PageSize = 10,
            IncludeTotalCount = true
        });

        var item = Assert.Single(page.Items);
        Assert.Equal(1, page.TotalCount);
        Assert.Equal(901, item.NotificationId);
        Assert.Equal("Billing", item.Notification?.Type);
    }

    [Fact]
    public async Task InsertAsync_AllAudience_SendsPushToAllActiveDeviceTokensOfActiveUsers()
    {
        var options = BuildOptions();
        await using var context = new AquaFlowDbContext(options);
        SeedUsersAndLocations(context);
        SeedDeviceTokens(context);

        var pushSender = new FakePushNotificationSender();
        var service = CreateNotificationService(context, pushSender);

        var response = await service.InsertAsync(new NotificationInsertRequest
        {
            Title = "Nova obavijest",
            Body = "Sadrzaj obavijesti",
            Type = "Info",
            Audience = "All",
            CreatedById = AdminUserId
        });

        var call = Assert.Single(pushSender.Calls);
        Assert.Equal("Nova obavijest", call.Title);
        Assert.Equal("Sadrzaj obavijesti", call.Body);
        Assert.Equal(response.Id.ToString(), call.Data["notificationId"]);
        Assert.Equal("Info", call.Data["type"]);
        Assert.Equal(
            new[] { "token-admin", "token-collector", "token-customer", "token-other-collector", "token-other-customer" }
                .OrderBy(token => token),
            call.Tokens.OrderBy(token => token));
        Assert.DoesNotContain("token-customer-inactive", call.Tokens);
    }

    [Theory]
    [InlineData("Customers", new[] { "token-customer", "token-other-customer" })]
    [InlineData("Collectors", new[] { "token-collector", "token-other-collector" })]
    public async Task InsertAsync_RoleAudience_SendsPushOnlyToThatRolesActiveTokens(string audience, string[] expectedTokens)
    {
        var options = BuildOptions();
        await using var context = new AquaFlowDbContext(options);
        SeedUsersAndLocations(context);
        SeedDeviceTokens(context);

        var pushSender = new FakePushNotificationSender();
        var service = CreateNotificationService(context, pushSender);

        await service.InsertAsync(new NotificationInsertRequest
        {
            Title = "Obavijest po ulozi",
            Body = "Sadrzaj obavijesti",
            Type = "Info",
            Audience = audience,
            CreatedById = AdminUserId
        });

        var call = Assert.Single(pushSender.Calls);
        Assert.Equal(expectedTokens.OrderBy(token => token), call.Tokens.OrderBy(token => token));
    }

    [Fact]
    public async Task InsertAsync_SettlementAudience_SendsPushOnlyToSettlementRecipients()
    {
        var options = BuildOptions();
        await using var context = new AquaFlowDbContext(options);
        SeedUsersAndLocations(context);
        SeedDeviceTokens(context);

        var pushSender = new FakePushNotificationSender();
        var service = CreateNotificationService(context, pushSender);

        await service.InsertAsync(new NotificationInsertRequest
        {
            Title = "Radovi u naselju",
            Body = "Planirani radovi na mrezi.",
            Type = "PlannedWorks",
            Audience = "Settlement",
            SettlementId = 10,
            CreatedById = AdminUserId
        });

        // Settlement 10 covers CollectorUserId and CustomerUserId only (see the
        // InsertAsync_SettlementAudience_CreatesInboxRowsForSettlementCustomersAndCollectors test above).
        var call = Assert.Single(pushSender.Calls);
        Assert.Equal(
            new[] { "token-collector", "token-customer" }.OrderBy(token => token),
            call.Tokens.OrderBy(token => token));
    }

    [Fact]
    public async Task InsertAsync_PushSenderThrows_StillReturnsNotificationResponse()
    {
        var options = BuildOptions();
        await using var context = new AquaFlowDbContext(options);
        SeedUsersAndLocations(context);
        SeedDeviceTokens(context);

        var pushSender = new FakePushNotificationSender { ExceptionToThrow = new InvalidOperationException("FCM unavailable") };
        var service = CreateNotificationService(context, pushSender);

        var response = await service.InsertAsync(new NotificationInsertRequest
        {
            Title = "Nova obavijest",
            Body = "Sadrzaj obavijesti",
            Type = "Info",
            Audience = "All",
            CreatedById = AdminUserId
        });

        Assert.True(response.Id > 0);
        Assert.True(await context.UserNotifications.AnyAsync(userNotification => userNotification.NotificationId == response.Id));
    }

    [Fact]
    public async Task InsertAsync_PushSenderReportsInvalidToken_DeactivatesThatDeviceToken()
    {
        var options = BuildOptions();
        await using var context = new AquaFlowDbContext(options);
        SeedUsersAndLocations(context);
        SeedDeviceTokens(context);

        var pushSender = new FakePushNotificationSender();
        pushSender.TokensToReportInvalid.Add("token-customer");
        var service = CreateNotificationService(context, pushSender);

        await service.InsertAsync(new NotificationInsertRequest
        {
            Title = "Nova obavijest",
            Body = "Sadrzaj obavijesti",
            Type = "Info",
            Audience = "All",
            CreatedById = AdminUserId
        });

        var deactivatedToken = await context.DeviceTokens.SingleAsync(deviceToken => deviceToken.Token == "token-customer");
        Assert.False(deactivatedToken.IsActive);

        var untouchedToken = await context.DeviceTokens.SingleAsync(deviceToken => deviceToken.Token == "token-admin");
        Assert.True(untouchedToken.IsActive);
    }

    [Fact]
    public async Task UpdateAsync_DoesNotSendPush()
    {
        var options = BuildOptions();
        await using var context = new AquaFlowDbContext(options);
        SeedUsersAndLocations(context);
        SeedDeviceTokens(context);

        var pushSender = new FakePushNotificationSender();
        var service = CreateNotificationService(context, pushSender);

        var response = await service.InsertAsync(new NotificationInsertRequest
        {
            Title = "Nova obavijest",
            Body = "Sadrzaj obavijesti",
            Type = "Info",
            Audience = "All",
            CreatedById = AdminUserId
        });
        pushSender.Calls.Clear();

        await service.UpdateAsync(response.Id, new NotificationUpdateRequest
        {
            Title = "Azurirana obavijest",
            Body = "Novi sadrzaj",
            Type = "Info",
            Audience = "All",
            CreatedById = AdminUserId
        });

        Assert.Empty(pushSender.Calls);
    }

    [Fact]
    public async Task PatchAsync_DoesNotSendPush()
    {
        var options = BuildOptions();
        await using var context = new AquaFlowDbContext(options);
        SeedUsersAndLocations(context);
        SeedDeviceTokens(context);

        var pushSender = new FakePushNotificationSender();
        var service = CreateNotificationService(context, pushSender);

        var response = await service.InsertAsync(new NotificationInsertRequest
        {
            Title = "Nova obavijest",
            Body = "Sadrzaj obavijesti",
            Type = "Info",
            Audience = "All",
            CreatedById = AdminUserId
        });
        pushSender.Calls.Clear();

        await service.PatchAsync(response.Id, new NotificationPatchRequest
        {
            Title = "Azurirani naslov"
        });

        Assert.Empty(pushSender.Calls);
    }

    [Fact]
    public async Task GetAllAsync_ForUser_FiltersByIsRead()
    {
        var options = BuildOptions();
        await using var context = new AquaFlowDbContext(options);
        SeedUsersAndLocations(context);
        context.Notifications.AddRange(
            new Notification
            {
                Id = 900,
                Title = "Nepročitana obavijest",
                Body = "Sadrzaj obavijesti.",
                Type = "Info",
                Audience = "Customers",
                CreatedById = AdminUserId,
                CreatedAt = DateTime.UtcNow
            },
            new Notification
            {
                Id = 901,
                Title = "Pročitana obavijest",
                Body = "Novi racun je dostupan.",
                Type = "Billing",
                Audience = "Customers",
                CreatedById = AdminUserId,
                CreatedAt = DateTime.UtcNow
            });
        await context.SaveChangesAsync();

        var service = CreateUserNotificationService(context);
        // Backfill both inbox rows for the customer first, then mark one read.
        await service.GetAllAsync(new UserNotificationSearchObject { UserId = CustomerUserId });
        var readRow = await context.UserNotifications.SingleAsync(userNotification =>
            userNotification.UserId == CustomerUserId && userNotification.NotificationId == 901);
        readRow.ReadAt = DateTime.UtcNow;
        await context.SaveChangesAsync();

        var unreadPage = await service.GetAllAsync(new UserNotificationSearchObject
        {
            UserId = CustomerUserId,
            IsRead = false,
            Page = 1,
            PageSize = 10,
            IncludeTotalCount = true
        });
        var unreadItem = Assert.Single(unreadPage.Items);
        Assert.Equal(1, unreadPage.TotalCount);
        Assert.Equal(900, unreadItem.NotificationId);

        var readPage = await service.GetAllAsync(new UserNotificationSearchObject
        {
            UserId = CustomerUserId,
            IsRead = true,
            Page = 1,
            PageSize = 10,
            IncludeTotalCount = true
        });
        var readItem = Assert.Single(readPage.Items);
        Assert.Equal(1, readPage.TotalCount);
        Assert.Equal(901, readItem.NotificationId);
    }

    private static NotificationService CreateNotificationService(
        AquaFlowDbContext context,
        IPushNotificationSender? pushNotificationSender = null)
    {
        // Mirrors Program.cs's AddPatchMapping, which only runs for the real app - a plain
        // `new Mapper()` here would map every null field on NotificationPatchRequest onto the
        // entity too (wiping e.g. Audience), same precedent as TariffServiceTests.CreateService.
        var mapperConfig = new TypeAdapterConfig();
        mapperConfig.NewConfig<NotificationPatchRequest, Notification>().IgnoreNullValues(true);
        IMapper mapper = new Mapper(mapperConfig);
        var recipientService = new NotificationRecipientService(context);

        return new NotificationService(
            context,
            mapper,
            new IValidator<NotificationInsertRequest>[] { new NotificationInsertValidator() },
            new IValidator<NotificationUpdateRequest>[] { new NotificationUpdateValidator() },
            new IValidator<NotificationPatchRequest>[] { new NotificationPatchValidator() },
            recipientService,
            pushNotificationSender ?? new FakePushNotificationSender(),
            NullLogger<NotificationService>.Instance);
    }

    private static UserNotificationService CreateUserNotificationService(AquaFlowDbContext context)
    {
        IMapper mapper = new Mapper();
        var recipientService = new NotificationRecipientService(context);

        return new UserNotificationService(
            context,
            mapper,
            Array.Empty<IValidator<UserNotificationInsertRequest>>(),
            Array.Empty<IValidator<UserNotificationUpdateRequest>>(),
            Array.Empty<IValidator<UserNotificationPatchRequest>>(),
            recipientService);
    }

    private static void SeedUsersAndLocations(AquaFlowDbContext context)
    {
        context.UserRoles.AddRange(
            new UserRole { Id = 1, Name = "Admin" },
            new UserRole { Id = 2, Name = "Collector" },
            new UserRole { Id = 3, Name = "Customer" });

        context.Users.AddRange(
            CreateUser(AdminUserId, 1),
            CreateUser(CollectorUserId, 2),
            CreateUser(CustomerUserId, 3),
            CreateUser(OtherCustomerUserId, 3),
            CreateUser(OtherCollectorUserId, 2),
            CreateUser(InactiveCustomerUserId, 3, isActive: false));

        context.CustomerProfiles.AddRange(
            new CustomerProfile { Id = 1, UserId = CustomerUserId, CustomerCode = "C-1", SettlementId = 10 },
            new CustomerProfile { Id = 2, UserId = OtherCustomerUserId, CustomerCode = "C-2", SettlementId = 20 },
            new CustomerProfile { Id = 3, UserId = InactiveCustomerUserId, CustomerCode = "C-3", SettlementId = 10 });

        context.CollectorProfiles.AddRange(
            new CollectorProfile { Id = 1, UserId = CollectorUserId, EmployeeCode = "COL-1", AssignedAreaId = 10 },
            new CollectorProfile { Id = 2, UserId = OtherCollectorUserId, EmployeeCode = "COL-2", AssignedAreaId = 20 });

        context.SaveChanges();
    }

    private static void SeedDeviceTokens(AquaFlowDbContext context)
    {
        context.DeviceTokens.AddRange(
            new DeviceToken { Id = 1, UserId = AdminUserId, Token = "token-admin", Platform = "android", IsActive = true },
            new DeviceToken { Id = 2, UserId = CollectorUserId, Token = "token-collector", Platform = "android", IsActive = true },
            new DeviceToken { Id = 3, UserId = CustomerUserId, Token = "token-customer", Platform = "ios", IsActive = true },
            new DeviceToken { Id = 4, UserId = CustomerUserId, Token = "token-customer-inactive", Platform = "ios", IsActive = false },
            new DeviceToken { Id = 5, UserId = OtherCustomerUserId, Token = "token-other-customer", Platform = "android", IsActive = true },
            new DeviceToken { Id = 6, UserId = OtherCollectorUserId, Token = "token-other-collector", Platform = "android", IsActive = true });

        context.SaveChanges();
    }

    private static User CreateUser(int id, int roleId, bool isActive = true)
    {
        return new User
        {
            Id = id,
            Email = $"user{id}@aquaflow.ba",
            PasswordHash = "hash",
            PasswordSalt = "salt",
            UserRoleId = roleId,
            IsActive = isActive
        };
    }

    private static DbContextOptions<AquaFlowDbContext> BuildOptions() =>
        new DbContextOptionsBuilder<AquaFlowDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .ConfigureWarnings(w => w.Ignore(InMemoryEventId.TransactionIgnoredWarning))
            .Options;
}
