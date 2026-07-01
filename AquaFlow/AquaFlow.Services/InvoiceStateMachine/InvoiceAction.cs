namespace AquaFlow.Services.InvoiceStateMachine;

// Canonical invoice action names surfaced by BaseInvoiceState.GetAllowedActions() and the
// GET {id}/allowed-actions endpoint. These are the clean verbs the API contract promises,
// deliberately without the "Async" method suffix, so the literals must not change; every state
// references these constants instead of raw strings to keep the contract in one place.
public static class InvoiceAction
{
    public const string Issue = "Issue";
    public const string RecordPayment = "RecordPayment";
    public const string Cancel = "Cancel";
    public const string MarkOverdue = "MarkOverdue";
}
