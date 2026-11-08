namespace AquaFlow.Model.SearchObjects;

public class LookupSearchObject : BaseSearchObject
{
    // Exact match.
    public string? Code { get; set; }
    // Contains, on Name, NameEn or NameDe.
    public string? Name { get; set; }
    public bool? IsActive { get; set; }
}
