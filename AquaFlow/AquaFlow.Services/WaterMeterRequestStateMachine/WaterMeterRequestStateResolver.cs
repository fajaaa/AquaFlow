using AquaFlow.Model.Exceptions;
using Microsoft.Extensions.DependencyInjection;

namespace AquaFlow.Services.WaterMeterRequestStateMachine;

// Resolves each water meter request state through the keyed BaseWaterMeterRequestState
// registrations in Program.cs, where the status string is the service key. States are keyed scoped
// services, so every resolution shares the current request's DbContext.
public class WaterMeterRequestStateResolver : IWaterMeterRequestStateResolver
{
    // The valid status keys, matching the keyed registrations. An unknown status is a client error,
    // not a missing service, so it is guarded here to keep the 400 (ClientException) behaviour.
    private static readonly IReadOnlySet<string> KnownStatuses = new HashSet<string>
    {
        WaterMeterRequestStatus.Pending,
        WaterMeterRequestStatus.Assigned,
        WaterMeterRequestStatus.Registered,
        WaterMeterRequestStatus.Rejected,
        WaterMeterRequestStatus.Cancelled
    };

    private readonly IServiceProvider _serviceProvider;

    public WaterMeterRequestStateResolver(IServiceProvider serviceProvider)
    {
        _serviceProvider = serviceProvider;
    }

    public BaseWaterMeterRequestState Resolve(string status)
    {
        if (status == null || !KnownStatuses.Contains(status))
        {
            throw new ClientException($"Unknown water meter request status '{status}'.");
        }

        return _serviceProvider.GetRequiredKeyedService<BaseWaterMeterRequestState>(status);
    }
}
