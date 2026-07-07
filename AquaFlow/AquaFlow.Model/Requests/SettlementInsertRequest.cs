namespace AquaFlow.Model.Requests;

public class SettlementInsertRequest
{
    public string Name { get; set; } = string.Empty;
    public int MunicipalityId { get; set; }
    public string PostalCode { get; set; } = string.Empty;
}
