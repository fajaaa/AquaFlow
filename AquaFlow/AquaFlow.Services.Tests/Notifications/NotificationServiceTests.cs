using AquaFlow.Model.Requests;
using AquaFlow.Model.SearchObjects;
using AquaFlow.Services.Database;
using AquaFlow.Services.Validators;
using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
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

    private static NotificationService CreateNotificationService(AquaFlowDbContext context)
    {
        IMapper mapper = new Mapper();
        var recipientService = new NotificationRecipientService(context);

        return new NotificationService(
            context,
            mapper,
            new IValidator<NotificationInsertRequest>[] { new NotificationInsertValidator() },
            new IValidator<NotificationUpdateRequest>[] { new NotificationUpdateValidator() },
            new IValidator<NotificationPatchRequest>[] { new NotificationPatchValidator() },
            recipientService);
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
            new CustomerProfile { Id = 1, UserId = CustomerUserId, CustomerCode = "C-1" },
            new CustomerProfile { Id = 2, UserId = OtherCustomerUserId, CustomerCode = "C-2" },
            new CustomerProfile { Id = 3, UserId = InactiveCustomerUserId, CustomerCode = "C-3" });

        context.CollectorProfiles.AddRange(
            new CollectorProfile { Id = 1, UserId = CollectorUserId, EmployeeCode = "COL-1", AssignedAreaId = 10 },
            new CollectorProfile { Id = 2, UserId = OtherCollectorUserId, EmployeeCode = "COL-2", AssignedAreaId = 20 });

        context.ServiceLocations.AddRange(
            new ServiceLocation { Id = 1, CustomerId = 1, SettlementId = 10, Address = "A", LocationType = "Home", IsActive = true },
            new ServiceLocation { Id = 2, CustomerId = 2, SettlementId = 20, Address = "B", LocationType = "Home", IsActive = true },
            new ServiceLocation { Id = 3, CustomerId = 3, SettlementId = 10, Address = "C", LocationType = "Home", IsActive = true });

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
