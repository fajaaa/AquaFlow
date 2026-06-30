namespace AquaFlow.Model.Requests;

public class PaymentSettingsPatchRequest
{
    public bool? AllowCardPayments { get; set; }
    public bool? AllowPayPalPayments { get; set; }
    public string? CardProvider { get; set; }
    public string? PayPalClientId { get; set; }
    public string? PayPalMerchantEmail { get; set; }
    public bool? IsTestMode { get; set; }
    public int? UpdatedById { get; set; }
}
