namespace AquaFlow.Model.Responses;

public class SettlementResponse : AuditableResponse
{
    public string Name { get; set; } = string.Empty;
    public string City { get; set; } = string.Empty;
    public string PostalCode { get; set; } = string.Empty;
}
