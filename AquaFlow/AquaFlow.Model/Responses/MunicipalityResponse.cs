namespace AquaFlow.Model.Responses;

public class MunicipalityResponse : AuditableResponse
{
    public string Name { get; set; } = string.Empty;
    public string Code { get; set; } = string.Empty;
    public int CityId { get; set; }
    public string CityName { get; set; } = string.Empty;
}
