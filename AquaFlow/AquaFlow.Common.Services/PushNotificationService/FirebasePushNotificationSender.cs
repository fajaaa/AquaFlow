using FirebaseAdmin;
using FirebaseAdmin.Messaging;
using Microsoft.Extensions.Logging;

namespace AquaFlow.Common.Services.PushNotificationService;

public class FirebasePushNotificationSender : IPushNotificationSender
{
    private const int MulticastBatchSize = 500;

    private readonly FirebaseApp _firebaseApp;
    private readonly ILogger<FirebasePushNotificationSender> _logger;

    public FirebasePushNotificationSender(FirebaseApp firebaseApp, ILogger<FirebasePushNotificationSender> logger)
    {
        _firebaseApp = firebaseApp;
        _logger = logger;
    }

    public async Task<List<string>> SendAsync(
        IEnumerable<string> tokens,
        string title,
        string body,
        IDictionary<string, string> data)
    {
        var tokenList = tokens.Where(token => !string.IsNullOrWhiteSpace(token)).Distinct().ToList();
        var invalidTokens = new List<string>();

        if (tokenList.Count == 0)
        {
            return invalidTokens;
        }

        var messaging = FirebaseMessaging.GetMessaging(_firebaseApp);

        for (var offset = 0; offset < tokenList.Count; offset += MulticastBatchSize)
        {
            var batch = tokenList.Skip(offset).Take(MulticastBatchSize).ToList();

            var message = new MulticastMessage
            {
                // DeviceToken.Token holds classic FCM registration tokens (see DeviceTokensController),
                // not Firebase Installation IDs, so Tokens is correct here despite being marked obsolete
                // in favor of Fids - the SDK still fully supports it during the migration period.
#pragma warning disable CS0618
                Tokens = batch,
#pragma warning restore CS0618
                Notification = new Notification { Title = title, Body = body },
                Data = new Dictionary<string, string>(data)
            };

            BatchResponse response;
            try
            {
                response = await messaging.SendEachForMulticastAsync(message);
            }
            catch (FirebaseMessagingException ex)
            {
                _logger.LogError(ex, "FCM multicast send failed for a batch of {Count} tokens.", batch.Count);
                continue;
            }

            for (var i = 0; i < response.Responses.Count; i++)
            {
                var sendResponse = response.Responses[i];
                if (sendResponse.IsSuccess)
                {
                    continue;
                }

                if (sendResponse.Exception?.MessagingErrorCode is MessagingErrorCode.Unregistered or MessagingErrorCode.InvalidArgument)
                {
                    invalidTokens.Add(batch[i]);
                }
                else
                {
                    _logger.LogWarning(sendResponse.Exception, "FCM push failed for a token.");
                }
            }
        }

        return invalidTokens;
    }
}
