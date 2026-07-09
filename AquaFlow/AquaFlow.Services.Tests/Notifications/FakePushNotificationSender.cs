using AquaFlow.Common.Services.PushNotificationService;

namespace AquaFlow.Services.Tests.Notifications;

public class FakePushNotificationSender : IPushNotificationSender
{
    public List<SendCall> Calls { get; } = new();
    public List<string> TokensToReportInvalid { get; set; } = new();
    public Exception? ExceptionToThrow { get; set; }

    public Task<List<string>> SendAsync(
        IEnumerable<string> tokens,
        string title,
        string body,
        IDictionary<string, string> data)
    {
        if (ExceptionToThrow is not null)
        {
            throw ExceptionToThrow;
        }

        var tokenList = tokens.ToList();
        Calls.Add(new SendCall(tokenList, title, body, data));

        return Task.FromResult(tokenList.Where(TokensToReportInvalid.Contains).ToList());
    }

    public record SendCall(List<string> Tokens, string Title, string Body, IDictionary<string, string> Data);
}
