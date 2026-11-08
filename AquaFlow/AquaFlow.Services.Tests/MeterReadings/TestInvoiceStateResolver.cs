using AquaFlow.Model.Exceptions;
using AquaFlow.Services.Database;
using AquaFlow.Services.InvoiceStateMachine;
using MapsterMapper;

namespace AquaFlow.Services.Tests.MeterReadings;

// Hand-wired IInvoiceStateResolver for MeterReadingService tests: the real states over the test's
// DbContext, with an optional override for the Issued state (e.g. one whose payment step throws).
internal sealed class TestInvoiceStateResolver : IInvoiceStateResolver
{
    private readonly Dictionary<string, BaseInvoiceState> _states;

    public TestInvoiceStateResolver(
        AquaFlowDbContext context,
        IMapper mapper,
        ISystemNotificationService systemNotifications,
        BaseInvoiceState? issuedOverride = null)
    {
        _states = new Dictionary<string, BaseInvoiceState>
        {
            [InvoiceStatus.Issued] = issuedOverride ?? new IssuedInvoiceState(context, mapper, systemNotifications),
            [InvoiceStatus.Paid] = new PaidInvoiceState(context, mapper, systemNotifications),
            [InvoiceStatus.Cancelled] = new CancelledInvoiceState(context, mapper, systemNotifications)
        };
    }

    public BaseInvoiceState Resolve(string status)
        => _states.TryGetValue(status, out var state) ? state : throw new ClientException($"Unknown invoice status '{status}'.");
}
