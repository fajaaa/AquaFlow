using AquaFlow.Common.Services.PushNotificationService;
using AquaFlow.Services.Database;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace AquaFlow.Services;

// The single FCM delivery path for every in-app notification - admin announcements
// (NotificationService.InsertAsync) and system notifications (SystemNotificationService) alike.
// It is always called AFTER the notification and its inbox rows are committed, and it never
// throws: an FCM outage, bad Firebase config or a DB error while reading tokens is logged and
// swallowed, so a push failure can never block or roll back the business operation that caused
// the notification. The in-app inbox row exists either way; push is only the "wake up the phone"
// extra on top of it.
public class NotificationPushDispatcher
{
    private const int PushBodyMaxLength = 150;

    private readonly AquaFlowDbContext _dbContext;
    private readonly IPushNotificationSender _pushNotificationSender;
    private readonly ILogger<NotificationPushDispatcher> _logger;

    public NotificationPushDispatcher(
        AquaFlowDbContext dbContext,
        IPushNotificationSender pushNotificationSender,
        ILogger<NotificationPushDispatcher> logger)
    {
        _dbContext = dbContext;
        _pushNotificationSender = pushNotificationSender;
        _logger = logger;
    }

    public async Task SendAsync(Notification notification, IReadOnlyCollection<int> recipientUserIds)
    {
        if (recipientUserIds.Count == 0)
        {
            return;
        }

        try
        {
            // UserPreference.ReceivePushNotifications only switches off the push - the inbox row was
            // already created. A user with no preference row gets the default (push on), so only an
            // explicit opt-out removes them here.
            var optedOutUserIds = await _dbContext.UserPreferences
                .Where(preference => recipientUserIds.Contains(preference.UserId) && !preference.ReceivePushNotifications)
                .Select(preference => preference.UserId)
                .ToListAsync();

            var pushUserIds = recipientUserIds.Except(optedOutUserIds).ToList();
            if (pushUserIds.Count == 0)
            {
                return;
            }

            var tokens = await _dbContext.DeviceTokens
                .Where(deviceToken => deviceToken.IsActive && pushUserIds.Contains(deviceToken.UserId))
                .Select(deviceToken => deviceToken.Token)
                .ToListAsync();

            if (tokens.Count == 0)
            {
                return;
            }

            var body = notification.Body.Length > PushBodyMaxLength
                ? notification.Body[..PushBodyMaxLength] + "..."
                : notification.Body;

            var data = new Dictionary<string, string>
            {
                ["notificationId"] = notification.Id.ToString(),
                ["type"] = notification.Type
            };

            // Deep-link target for a system notification (FCM data values must be strings, so the
            // keys are simply omitted for an admin notification that has none).
            if (notification.RelatedEntityType != null && notification.RelatedEntityId != null)
            {
                data["relatedEntityType"] = notification.RelatedEntityType;
                data["relatedEntityId"] = notification.RelatedEntityId.Value.ToString();
            }

            var invalidTokens = await _pushNotificationSender.SendAsync(tokens, notification.Title, body, data);

            if (invalidTokens.Count > 0)
            {
                // Tracked fetch-then-save rather than ExecuteUpdateAsync, same style as
                // DeviceTokenService - the InMemory provider the tests use doesn't reliably support
                // set-based updates.
                var tokensToDeactivate = await _dbContext.DeviceTokens
                    .Where(deviceToken => invalidTokens.Contains(deviceToken.Token) && deviceToken.IsActive)
                    .ToListAsync();

                foreach (var deviceToken in tokensToDeactivate)
                {
                    deviceToken.IsActive = false;
                }

                await _dbContext.SaveChangesAsync();
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send push notification for notification {NotificationId}.", notification.Id);
        }
    }
}
