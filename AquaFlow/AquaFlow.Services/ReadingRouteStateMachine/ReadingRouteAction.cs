namespace AquaFlow.Services.ReadingRouteStateMachine;

// Canonical reading route action names surfaced by BaseReadingRouteState.GetAllowedActions()
// and the GET {id}/allowed-actions endpoint. These are the clean verbs the API contract promises,
// deliberately without the "Async" method suffix, so the literals must not change; every state
// references these constants instead of raw strings to keep the contract in one place.
//
// InProgress/Complete actions are deliberately not included yet - they land later when field
// reading/billing is implemented (see the same note on ReadingRouteStatus).
public static class ReadingRouteAction
{
    public const string Assign = "Assign";
    public const string Cancel = "Cancel";
}
