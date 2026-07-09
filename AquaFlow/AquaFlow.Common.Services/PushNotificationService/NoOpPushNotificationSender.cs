using Microsoft.Extensions.Logging;

namespace AquaFlow.Common.Services.PushNotificationService;

public class NoOpPushNotificationSender : IPushNotificationSender
{
    private readonly ILogger<NoOpPushNotificationSender> _logger;

    public NoOpPushNotificationSender(ILogger<NoOpPushNotificationSender> logger)
    {
        _logger = logger;
    }

    public Task<List<string>> SendAsync(
        IEnumerable<string> tokens,
        string title,
        string body,
        IDictionary<string, string> data)
    {
        _logger.LogWarning("Firebase not configured, push disabled");
        return Task.FromResult(new List<string>());
    }
}
