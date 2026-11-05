namespace AquaFlow.Services;

// Canonical payment method values persisted to the database; the literals must not change.
public static class PaymentMethod
{
    public const string Manual = "Manual";
    // A payment started through a checkout session (IPaymentProvider), as opposed to one an admin
    // types in directly against RecordPaymentAsync.
    public const string Online = "Online";
    // Cash a collector took from the present customer when entering the reading that issued the
    // invoice (MeterReadingService.CreateForCollectorAsync). Provider stays PaymentProvider.Manual.
    public const string Cash = "Cash";
}
