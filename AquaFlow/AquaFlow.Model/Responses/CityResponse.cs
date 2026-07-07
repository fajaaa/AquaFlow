namespace AquaFlow.Model.Responses;

public class CityResponse : AuditableResponse
{
    public string Name { get; set; } = string.Empty;
    public string Code { get; set; } = string.Empty;
}
