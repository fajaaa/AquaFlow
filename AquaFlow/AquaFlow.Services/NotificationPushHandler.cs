using AquaFlow.Model.Messages;
using AquaFlow.Services.Database;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace AquaFlow.Services;

// Handles one NotificationPushRequested message: idempotent, retried with exponential backoff,
// rethrows after the last attempt so the message bus moves it to its error queue. Kept out of the
// Subscriber host so it is testable without RabbitMQ.
public class NotificationPushHandler
{
    public const int MaxAttempts = 3;

    private readonly AquaFlowDbContext _dbContext;
    private readonly NotificationPushDispatcher _dispatcher;
    private readonly ILogger<NotificationPushHandler> _logger;
    private readonly Func<TimeSpan, CancellationToken, Task> _delay;

    public NotificationPushHandler(
        AquaFlowDbContext dbContext,
        NotificationPushDispatcher dispatcher,
        ILogger<NotificationPushHandler> logger,
        Func<TimeSpan, CancellationToken, Task>? delay = null)
    {
        _dbContext = dbContext;
        _dispatcher = dispatcher;
        _logger = logger;
        _delay = delay ?? Task.Delay;
    }

    public async Task HandleAsync(NotificationPushRequested message, CancellationToken cancellationToken = default)
    {
        var notification = await _dbContext.Notifications
            .AsNoTracking()
            .FirstOrDefaultAsync(n => n.Id == message.NotificationId, cancellationToken);

        if (notification is null)
        {
            _logger.LogWarning("Notification {NotificationId} not found; skipping push.", message.NotificationId);
            return;
        }

        if (notification.PushDispatchedAt is not null)
        {
            _logger.LogInformation("Notification {NotificationId} already delivered; skipping.", message.NotificationId);
            return;
        }

        for (var attempt = 1; ; attempt++)
        {
            try
            {
                await _dispatcher.SendAsync(notification, message.RecipientUserIds);

                var tracked = await _dbContext.Notifications.FirstAsync(n => n.Id == notification.Id, cancellationToken);
                tracked.PushDispatchedAt = DateTime.UtcNow;
                await _dbContext.SaveChangesAsync(cancellationToken);
                return;
            }
            catch (Exception ex) when (attempt < MaxAttempts && !cancellationToken.IsCancellationRequested)
            {
                _logger.LogWarning(ex, "Push attempt {Attempt}/{MaxAttempts} failed for notification {NotificationId}.",
                    attempt, MaxAttempts, message.NotificationId);
                await _delay(TimeSpan.FromSeconds(Math.Pow(2, attempt)), cancellationToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Push delivery failed for notification {NotificationId} after {Attempt} attempts.",
                    message.NotificationId, attempt);
                throw;
            }
        }
    }
}
