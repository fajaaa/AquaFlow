using AquaFlow.Model.Exceptions;
using Microsoft.Extensions.DependencyInjection;

namespace AquaFlow.Services.InvoiceStateMachine;

// Resolves each invoice state through the keyed BaseInvoiceState registrations in Program.cs, where
// the status string is the service key. States are keyed scoped services, so every resolution shares
// the current request's DbContext.
public class InvoiceStateResolver : IInvoiceStateResolver
{
    // The valid status keys, matching the keyed registrations. An unknown status is a client error,
    // not a missing service, so it is guarded here to keep the 400 (ClientException) behaviour.
    private static readonly IReadOnlySet<string> KnownStatuses = new HashSet<string>
    {
        InvoiceStatus.Draft,
        InvoiceStatus.Issued,
        InvoiceStatus.PartiallyPaid,
        InvoiceStatus.Overdue,
        InvoiceStatus.Paid,
        InvoiceStatus.Cancelled
    };

    private readonly IServiceProvider _serviceProvider;

    public InvoiceStateResolver(IServiceProvider serviceProvider)
    {
        _serviceProvider = serviceProvider;
    }

    public BaseInvoiceState Resolve(string status)
    {
        if (status == null || !KnownStatuses.Contains(status))
        {
            throw new ClientException($"Unknown invoice status '{status}'.");
        }

        return _serviceProvider.GetRequiredKeyedService<BaseInvoiceState>(status);
    }
}
