namespace AquaFlow.Model.Requests;

public class PaymentSettingsInsertRequest
{
    public bool AllowCardPayments { get; set; }
    public bool AllowPayPalPayments { get; set; }
    public string? CardProvider { get; set; }
    public string? PayPalClientId { get; set; }
    public string? PayPalMerchantEmail { get; set; }
    public bool IsTestMode { get; set; } = true;
    public int UpdatedById { get; set; }
}
