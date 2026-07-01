namespace AquaFlow.Services.InvoiceStateMachine;

// Resolves the concrete Invoice state registered for a given status value. Replaces the former
// BaseInvoiceState.GetState factory so the base class stays a pure state.
public interface IInvoiceStateResolver
{
    // Returns the state registered for the status, or throws ClientException (400) for an unknown one.
    BaseInvoiceState Resolve(string status);
}
