namespace AquaFlow.Services.Payments;

// Bound from the "Payments" configuration section (Payments:Provider, Payments:Currency). Provider
// selects which IPaymentProvider Program.cs registers; Currency has no column to persist against
// (Payment carries no currency today) and is only surfaced in CheckoutSessionResponse.
public class PaymentsOptions
{
    public string Provider { get; set; } = AquaFlow.Services.PaymentProvider.Manual;
    public string Currency { get; set; } = "BAM";
}
