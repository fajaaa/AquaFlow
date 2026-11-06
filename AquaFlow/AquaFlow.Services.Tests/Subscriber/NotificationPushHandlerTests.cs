using AquaFlow.Model.Messages;
using AquaFlow.Services.Database;
using AquaFlow.Services.Tests.Notifications;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging.Abstractions;
using Xunit;

namespace AquaFlow.Services.Tests.Subscriber;

public class NotificationPushHandlerTests
{
    private const int NotificationId = 10;

    private static (AquaFlowDbContext Context, NotificationPushHandler Handler, List<TimeSpan> Delays) Create(
        FakePushNotificationSender sender)
    {
        var context = new AquaFlowDbContext(NotificationServiceTests.BuildOptions());
        var delays = new List<TimeSpan>();
        var dispatcher = new NotificationPushDispatcher(context, sender, NullLogger<NotificationPushDispatcher>.Instance);
        var handler = new NotificationPushHandler(
            context, dispatcher, NullLogger<NotificationPushHandler>.Instance,
            (delay, _) => { delays.Add(delay); return Task.CompletedTask; });
        return (context, handler, delays);
    }

    private static void Seed(AquaFlowDbContext context, DateTime? dispatchedAt = null)
    {
        context.Notifications.Add(new Notification
        {
            Id = NotificationId, Title = "T", Body = "B", Type = "Info", Audience = "All",
            CreatedById = 1, CreatedAt = DateTime.UtcNow, PushDispatchedAt = dispatchedAt
        });
        context.DeviceTokens.AddRange(
            new DeviceToken { Id = 1, UserId = 2, Platform = "android", Token = "tok-a", IsActive = true },
            new DeviceToken { Id = 2, UserId = 2, Platform = "android", Token = "tok-off", IsActive = false },
            new DeviceToken { Id = 3, UserId = 3, Platform = "android", Token = "tok-b", IsActive = true },
            new DeviceToken { Id = 4, UserId = 9, Platform = "android", Token = "tok-other", IsActive = true });
        context.SaveChanges();
    }

    private static NotificationPushRequested Message(int id = NotificationId) => new()
    {
        NotificationId = id, RecipientUserIds = new List<int> { 2, 3 }, RequestedAt = DateTime.UtcNow
    };

    [Fact]
    public async Task Handle_SendsToActiveTokensAndMarksDispatched()
    {
        var sender = new FakePushNotificationSender();
        var (context, handler, _) = Create(sender);
        await using var _ctx = context;
        Seed(context);

        await handler.HandleAsync(Message());

        var call = Assert.Single(sender.Calls);
        Assert.Equal(new[] { "tok-a", "tok-b" }, call.Tokens.OrderBy(t => t));
        Assert.NotNull((await context.Notifications.AsNoTracking().SingleAsync()).PushDispatchedAt);
    }

    [Fact]
    public async Task Handle_AlreadyDispatched_DoesNotSend()
    {
        var sender = new FakePushNotificationSender();
        var (context, handler, _) = Create(sender);
        await using var _ctx = context;
        Seed(context, DateTime.UtcNow.AddMinutes(-1));

        await handler.HandleAsync(Message());

        Assert.Empty(sender.Calls);
    }

    [Fact]
    public async Task Handle_MissingNotification_DoesNotThrowOrSend()
    {
        var sender = new FakePushNotificationSender();
        var (context, handler, _) = Create(sender);
        await using var _ctx = context;

        await handler.HandleAsync(Message(999));

        Assert.Empty(sender.Calls);
    }

    [Fact]
    public async Task Handle_FailsTwiceThenSucceeds_DeliversAfterRetries()
    {
        var sender = new FlakySender(failures: 2);
        var (context, handler, delays) = CreateWith(sender);
        await using var _ctx = context;
        Seed(context);

        await handler.HandleAsync(Message());

        Assert.Equal(3, sender.Attempts);
        Assert.Equal(new[] { TimeSpan.FromSeconds(2), TimeSpan.FromSeconds(4) }, delays);
        Assert.NotNull((await context.Notifications.AsNoTracking().SingleAsync()).PushDispatchedAt);
    }

    [Fact]
    public async Task Handle_AlwaysFails_RethrowsAfterThreeAttemptsAndStaysUndelivered()
    {
        var sender = new FlakySender(failures: int.MaxValue);
        var (context, handler, _) = CreateWith(sender);
        await using var _ctx = context;
        Seed(context);

        await Assert.ThrowsAsync<InvalidOperationException>(() => handler.HandleAsync(Message()));

        Assert.Equal(3, sender.Attempts);
        Assert.Null((await context.Notifications.AsNoTracking().SingleAsync()).PushDispatchedAt);
    }

    [Fact]
    public async Task Handle_InvalidToken_IsDeactivated()
    {
        var sender = new FakePushNotificationSender { TokensToReportInvalid = new List<string> { "tok-b" } };
        var (context, handler, _) = Create(sender);
        await using var _ctx = context;
        Seed(context);

        await handler.HandleAsync(Message());

        Assert.False((await context.DeviceTokens.AsNoTracking().SingleAsync(t => t.Token == "tok-b")).IsActive);
        Assert.True((await context.DeviceTokens.AsNoTracking().SingleAsync(t => t.Token == "tok-a")).IsActive);
    }

    private static (AquaFlowDbContext Context, NotificationPushHandler Handler, List<TimeSpan> Delays) CreateWith(
        AquaFlow.Common.Services.PushNotificationService.IPushNotificationSender sender)
    {
        var context = new AquaFlowDbContext(NotificationServiceTests.BuildOptions());
        var delays = new List<TimeSpan>();
        var dispatcher = new NotificationPushDispatcher(context, sender, NullLogger<NotificationPushDispatcher>.Instance);
        var handler = new NotificationPushHandler(
            context, dispatcher, NullLogger<NotificationPushHandler>.Instance,
            (delay, _) => { delays.Add(delay); return Task.CompletedTask; });
        return (context, handler, delays);
    }

    private sealed class FlakySender : AquaFlow.Common.Services.PushNotificationService.IPushNotificationSender
    {
        private readonly int _failures;
        public int Attempts { get; private set; }

        public FlakySender(int failures) => _failures = failures;

        public Task<List<string>> SendAsync(IEnumerable<string> tokens, string title, string body, IDictionary<string, string> data)
        {
            Attempts++;
            if (Attempts <= _failures)
            {
                throw new InvalidOperationException("FCM down");
            }
            return Task.FromResult(new List<string>());
        }
    }
}
