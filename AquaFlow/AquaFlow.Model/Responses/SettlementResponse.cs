namespace AquaFlow.Model.Responses;

public class SettlementResponse : AuditableResponse
{
    public string Name { get; set; } = string.Empty;
    public int MunicipalityId { get; set; }
    public string MunicipalityName { get; set; } = string.Empty;
    public string PostalCode { get; set; } = string.Empty;
}
