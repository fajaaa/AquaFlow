namespace AquaFlow.Model.Requests;

public class MunicipalityInsertRequest
{
    public string Name { get; set; } = string.Empty;
    public string Code { get; set; } = string.Empty;
    public int CityId { get; set; }
}
