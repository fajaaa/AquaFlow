namespace AquaFlow.Services.FaultReportStateMachine;

// Canonical fault report action names surfaced by BaseFaultReportState.GetAllowedActions() and the
// GET {id}/allowed-actions endpoint. These are the clean verbs the API contract promises,
// deliberately without the "Async" method suffix, so the literals must not change; every state
// references these constants instead of raw strings to keep the contract in one place.
public static class FaultReportAction
{
    public const string Start = "Start";
    public const string Resolve = "Resolve";
}
