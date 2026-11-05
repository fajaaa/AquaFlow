namespace AquaFlow.Model.Requests;

public class LookupPatchRequest
{
    public string? Code { get; set; }
    public string? Name { get; set; }
    public string? NameEn { get; set; }
    public string? NameDe { get; set; }
    public int? SortOrder { get; set; }
    public bool? IsActive { get; set; }
}
