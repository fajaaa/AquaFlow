namespace AquaFlow.Services;

// Canonical payment status values persisted to the database; the literals must not change.
public static class PaymentStatus
{
    public const string Pending = "Pending";
    public const string Completed = "Completed";
    public const string Failed = "Failed";
    public const string Refunded = "Refunded";
}
