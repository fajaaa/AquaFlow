using Microsoft.Extensions.Logging;

namespace AquaFlow.Common.Services.MessageBus;

public class NoOpMessagePublisher : IMessagePublisher
{
    private readonly ILogger<NoOpMessagePublisher> _logger;

    public NoOpMessagePublisher(ILogger<NoOpMessagePublisher> logger)
    {
        _logger = logger;
    }

    public Task PublishAsync<T>(T message) where T : class
    {
        _logger.LogWarning("RabbitMQ not configured, message publishing disabled");
        return Task.CompletedTask;
    }
}
