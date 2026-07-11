namespace AquaFlow.Services.FaultReportStateMachine;

// Resolves the concrete FaultReport state registered for a given status value, mirroring
// IInvoiceStateResolver/IWaterMeterRequestStateResolver.
public interface IFaultReportStateResolver
{
    // Returns the state registered for the status, or throws ClientException (400) for an unknown one.
    BaseFaultReportState Resolve(string status);
}
