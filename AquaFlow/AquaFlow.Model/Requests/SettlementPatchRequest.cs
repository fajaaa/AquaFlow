namespace AquaFlow.Model.Requests;

public class SettlementPatchRequest
{
    public string? Name { get; set; }
    public int? MunicipalityId { get; set; }
    public string? PostalCode { get; set; }
}
