namespace AquaFlow.Model.Responses;

// One row of any codebook (InvoiceStatuses, PaymentMethods, NotificationTypes, ...).
public class LookupResponse : AuditableResponse
{
    public string Code { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string? NameEn { get; set; }
    public string? NameDe { get; set; }
    public int SortOrder { get; set; }
    public bool IsSystem { get; set; }
    public bool IsActive { get; set; }
}
