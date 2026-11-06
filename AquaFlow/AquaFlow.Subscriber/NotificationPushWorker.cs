using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using AquaFlow.Model.Messages;
using AquaFlow.Services;
using EasyNetQ;

namespace AquaFlow.Subscriber;

public class NotificationPushWorker : BackgroundService
{
    private const string SubscriptionId = "aquaflow-push-delivery";

    private readonly IBus _bus;
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<NotificationPushWorker> _logger;

    public NotificationPushWorker(IBus bus, IServiceScopeFactory scopeFactory, ILogger<NotificationPushWorker> logger)
    {
        _bus = bus;
        _scopeFactory = scopeFactory;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        // RabbitMQ may still be starting up when this container does (e.g. under docker compose),
        // so subscribing is retried with exponential backoff instead of crashing on the first attempt.
        var backoff = TimeSpan.FromSeconds(1);
        var maxBackoff = TimeSpan.FromSeconds(30);

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await _bus.PubSub.SubscribeAsync<NotificationPushRequested>(
                    SubscriptionId, HandleAsync, _ => { }, stoppingToken);
                _logger.LogInformation("Subscribed to NotificationPushRequested as {SubscriptionId}.", SubscriptionId);
                break;
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
            {
                return;
            }
            catch (Exception ex)
            {
                _logger.LogWarning("Failed to connect/subscribe to RabbitMQ: {Message}. Retrying in {Seconds:0}s...",
                    ex.Message, backoff.TotalSeconds);
                try
                {
                    await Task.Delay(backoff, stoppingToken);
                }
                catch (OperationCanceledException)
                {
                    return;
                }
                backoff = TimeSpan.FromSeconds(Math.Min(backoff.TotalSeconds * 2, maxBackoff.TotalSeconds));
            }
        }

        try
        {
            await Task.Delay(Timeout.Infinite, stoppingToken);
        }
        catch (OperationCanceledException)
        {
            // Expected on shutdown.
        }
    }

    private async Task HandleAsync(NotificationPushRequested message, CancellationToken cancellationToken)
    {
        using var scope = _scopeFactory.CreateScope();
        var handler = scope.ServiceProvider.GetRequiredService<NotificationPushHandler>();
        await handler.HandleAsync(message, cancellationToken);
    }
}
