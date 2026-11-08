using FirebaseAdmin;
using Google.Apis.Auth.OAuth2;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace AquaFlow.Common.Services.PushNotificationService;

public static class PushServiceCollectionExtensions
{
    // Firebase Cloud Messaging (push notifications) is optional: a missing/invalid value here must
    // not stop the host from starting. When neither Firebase:ServiceAccountJson nor
    // Firebase:ServiceAccountJsonPath resolves to a usable credential, a no-op
    // IPushNotificationSender is registered instead (logs a warning and sends nothing).
    public static IServiceCollection AddFirebasePush(this IServiceCollection services, IConfiguration configuration)
    {
        var serviceAccountJson = configuration["Firebase:ServiceAccountJson"];
        var serviceAccountJsonPath = configuration["Firebase:ServiceAccountJsonPath"];
        var projectId = configuration["Firebase:ProjectId"];

        FirebaseApp? firebaseApp = null;
        if (!string.IsNullOrWhiteSpace(serviceAccountJson))
        {
            firebaseApp = FirebaseApp.Create(new AppOptions
            {
                Credential = CredentialFactory.FromJson<ServiceAccountCredential>(serviceAccountJson).ToGoogleCredential(),
                ProjectId = string.IsNullOrWhiteSpace(projectId) ? null : projectId
            });
        }
        else if (!string.IsNullOrWhiteSpace(serviceAccountJsonPath) && File.Exists(serviceAccountJsonPath))
        {
            firebaseApp = FirebaseApp.Create(new AppOptions
            {
                Credential = CredentialFactory.FromFile<ServiceAccountCredential>(serviceAccountJsonPath).ToGoogleCredential(),
                ProjectId = string.IsNullOrWhiteSpace(projectId) ? null : projectId
            });
        }

        if (firebaseApp is not null)
        {
            services.AddSingleton(firebaseApp);
            services.AddScoped<IPushNotificationSender, FirebasePushNotificationSender>();
        }
        else
        {
            services.AddScoped<IPushNotificationSender, NoOpPushNotificationSender>();
        }

        return services;
    }
}
