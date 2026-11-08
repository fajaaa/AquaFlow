using AquaFlow.Common.Services.MessageBus;
using AquaFlow.Services.Database;
using Microsoft.Extensions.Logging.Abstractions;

namespace AquaFlow.Services.Tests.Notifications;

// Builds the real SystemNotificationService over the test's DbContext, with RabbitMQ replaced by a fake
// publisher (the API only publishes NotificationPushRequested; it never talks to FCM).
// In the app it is scoped, so the state machine that stages a notification and the service that
// dispatches its push request share ONE instance - a test must pass the same instance to both too, or the
// request for a notification staged by a state would never be published.
public static class TestSystemNotifications
{
    public static SystemNotificationService Create(AquaFlowDbContext context, IMessagePublisher? publisher = null)
        => new(context, CreatePublisher(publisher));

    public static NotificationPushPublisher CreatePublisher(IMessagePublisher? publisher = null)
        => new(publisher ?? new FakeMessagePublisher(), NullLogger<NotificationPushPublisher>.Instance);
}
