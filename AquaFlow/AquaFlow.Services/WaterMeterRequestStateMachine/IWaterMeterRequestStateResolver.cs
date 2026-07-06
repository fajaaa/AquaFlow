namespace AquaFlow.Services.WaterMeterRequestStateMachine;

// Resolves the concrete WaterMeterRequest state registered for a given status value, mirroring
// IInvoiceStateResolver.
public interface IWaterMeterRequestStateResolver
{
    // Returns the state registered for the status, or throws ClientException (400) for an unknown one.
    BaseWaterMeterRequestState Resolve(string status);
}
