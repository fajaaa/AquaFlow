namespace AquaFlow.Services;

// Canonical invoice status values. These are the exact strings persisted to the database and
// returned by the API, so the literals must not change; this class only removes the duplication.
public static class InvoiceStatus
{
    public const string Draft = "Draft";
    public const string Issued = "Issued";
    public const string PartiallyPaid = "PartiallyPaid";
    public const string Overdue = "Overdue";
    public const string Paid = "Paid";
    public const string Cancelled = "Cancelled";
}
