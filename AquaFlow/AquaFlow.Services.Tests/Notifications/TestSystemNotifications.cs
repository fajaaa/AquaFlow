using AquaFlow.Common.Services.PushNotificationService;
using AquaFlow.Services.Database;
using Microsoft.Extensions.Logging.Abstractions;

namespace AquaFlow.Services.Tests.Notifications;

// Builds the real SystemNotificationService over the test's DbContext, with FCM replaced by a fake.
// In the app it is scoped, so the state machine that stages a notification and the service that
// dispatches its push share ONE instance - a test must pass the same instance to both too, or the
// push for a notification staged by a state would never be dispatched.
public static class TestSystemNotifications
{
    public static SystemNotificationService Create(AquaFlowDbContext context, IPushNotificationSender? pushSender = null)
        => new(context, CreateDispatcher(context, pushSender));

    public static NotificationPushDispatcher CreateDispatcher(AquaFlowDbContext context, IPushNotificationSender? pushSender = null)
        => new(context, pushSender ?? new FakePushNotificationSender(), NullLogger<NotificationPushDispatcher>.Instance);
}
