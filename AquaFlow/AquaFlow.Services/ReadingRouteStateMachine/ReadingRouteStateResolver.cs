using AquaFlow.Model.Exceptions;
using Microsoft.Extensions.DependencyInjection;

namespace AquaFlow.Services.ReadingRouteStateMachine;

// Resolves each reading route state through the keyed BaseReadingRouteState registrations in
// Program.cs, where the status string is the service key. States are keyed scoped services, so
// every resolution shares the current request's DbContext.
public class ReadingRouteStateResolver : IReadingRouteStateResolver
{
    // The valid status keys, matching the keyed registrations. An unknown status is a client error,
    // not a missing service, so it is guarded here to keep the 400 (ClientException) behaviour.
    private static readonly IReadOnlySet<string> KnownStatuses = new HashSet<string>
    {
        ReadingRouteStatus.Planned,
        ReadingRouteStatus.Assigned,
        ReadingRouteStatus.Cancelled
    };

    private readonly IServiceProvider _serviceProvider;

    public ReadingRouteStateResolver(IServiceProvider serviceProvider)
    {
        _serviceProvider = serviceProvider;
    }

    public BaseReadingRouteState Resolve(string status)
    {
        if (status == null || !KnownStatuses.Contains(status))
        {
            throw new ClientException($"Unknown reading route status '{status}'.");
        }

        return _serviceProvider.GetRequiredKeyedService<BaseReadingRouteState>(status);
    }
}
