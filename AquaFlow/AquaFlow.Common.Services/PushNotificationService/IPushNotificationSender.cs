namespace AquaFlow.Common.Services.PushNotificationService;

public interface IPushNotificationSender
{
    Task<List<string>> SendAsync(
        IEnumerable<string> tokens,
        string title,
        string body,
        IDictionary<string, string> data);
}
