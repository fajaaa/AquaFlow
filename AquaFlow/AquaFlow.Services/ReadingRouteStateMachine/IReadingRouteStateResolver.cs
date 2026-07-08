namespace AquaFlow.Services.ReadingRouteStateMachine;

// Resolves the concrete ReadingRoute state registered for a given status value, mirroring
// IWaterMeterRequestStateResolver.
public interface IReadingRouteStateResolver
{
    // Returns the state registered for the status, or throws ClientException (400) for an unknown one.
    BaseReadingRouteState Resolve(string status);
}
