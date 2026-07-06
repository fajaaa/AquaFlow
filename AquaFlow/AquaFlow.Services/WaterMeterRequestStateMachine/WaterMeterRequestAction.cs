namespace AquaFlow.Services.WaterMeterRequestStateMachine;

// Canonical water meter request action names surfaced by BaseWaterMeterRequestState.GetAllowedActions()
// and the GET {id}/allowed-actions endpoint. These are the clean verbs the API contract promises,
// deliberately without the "Async" method suffix, so the literals must not change; every state
// references these constants instead of raw strings to keep the contract in one place.
public static class WaterMeterRequestAction
{
    public const string Assign = "Assign";
    public const string Reject = "Reject";
    public const string Cancel = "Cancel";
    public const string Register = "Register";
}
