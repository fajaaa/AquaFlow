namespace AquaFlow.Model.Requests;

public class MunicipalityPatchRequest
{
    public string? Name { get; set; }
    public string? Code { get; set; }
    public int? CityId { get; set; }
}
