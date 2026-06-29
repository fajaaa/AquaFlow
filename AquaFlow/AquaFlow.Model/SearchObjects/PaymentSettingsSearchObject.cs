namespace AquaFlow.Model.SearchObjects;

public class PaymentSettingsSearchObject : BaseSearchObject
{
    public bool? AllowCardPayments { get; set; }
    public bool? AllowPayPalPayments { get; set; }
    public bool? IsTestMode { get; set; }
}
