using AquaFlow.Common.Services.MessageBus;
using AquaFlow.Model.Messages;
using Microsoft.Extensions.Logging;

namespace AquaFlow.Services;

public interface INotificationPushPublisher
{
    Task PublishAsync(int notificationId, IReadOnlyCollection<int> recipientUserIds);
}

// The API never talks to FCM: after a notification and its inbox rows are committed it only
// publishes NotificationPushRequested, and AquaFlow.Subscriber owns delivery. Publishing is
// best-effort - the inbox row is already committed, so a broker outage must not fail the request.
public class NotificationPushPublisher : INotificationPushPublisher
{
    private static int _noOpWarningLogged;

    private readonly IMessagePublisher _messagePublisher;
    private readonly ILogger<NotificationPushPublisher> _logger;

    public NotificationPushPublisher(IMessagePublisher messagePublisher, ILogger<NotificationPushPublisher> logger)
    {
        _messagePublisher = messagePublisher;
        _logger = logger;
    }

    public async Task PublishAsync(int notificationId, IReadOnlyCollection<int> recipientUserIds)
    {
        if (recipientUserIds.Count == 0)
        {
            return;
        }

        if (_messagePublisher is NoOpMessagePublisher &&
            Interlocked.Exchange(ref _noOpWarningLogged, 1) == 0)
        {
            _logger.LogWarning(
                "RabbitMQ is not configured: push delivery is disabled, NotificationPushRequested messages will not be published.");
        }

        try
        {
            await _messagePublisher.PublishAsync(new NotificationPushRequested
            {
                NotificationId = notificationId,
                RecipientUserIds = recipientUserIds.ToList(),
                RequestedAt = DateTime.UtcNow
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to publish NotificationPushRequested for notification {NotificationId}.", notificationId);
        }
    }
}
