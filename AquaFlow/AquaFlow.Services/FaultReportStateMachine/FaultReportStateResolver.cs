using AquaFlow.Model.Exceptions;
using Microsoft.Extensions.DependencyInjection;

namespace AquaFlow.Services.FaultReportStateMachine;

// Resolves each fault report state through the keyed BaseFaultReportState registrations in
// Program.cs, where the status string is the service key. States are keyed scoped services, so
// every resolution shares the current request's DbContext.
public class FaultReportStateResolver : IFaultReportStateResolver
{
    // The valid status keys, matching the keyed registrations. An unknown status is a client error,
    // not a missing service, so it is guarded here to keep the 400 (ClientException) behaviour.
    private static readonly IReadOnlySet<string> KnownStatuses = new HashSet<string>
    {
        FaultReportStatus.New,
        FaultReportStatus.Assigned,
        FaultReportStatus.InProgress,
        FaultReportStatus.Resolved
    };

    private readonly IServiceProvider _serviceProvider;

    public FaultReportStateResolver(IServiceProvider serviceProvider)
    {
        _serviceProvider = serviceProvider;
    }

    public BaseFaultReportState Resolve(string status)
    {
        if (status == null || !KnownStatuses.Contains(status))
        {
            throw new ClientException($"Unknown fault report status '{status}'.");
        }

        return _serviceProvider.GetRequiredKeyedService<BaseFaultReportState>(status);
    }
}
