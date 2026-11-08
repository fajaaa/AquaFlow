namespace AquaFlow.Model.Requests;

// IsSystem is deliberately absent: only the seed creates system rows.
public class LookupInsertRequest
{
    public string Code { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string? NameEn { get; set; }
    public string? NameDe { get; set; }
    public int SortOrder { get; set; }
    public bool IsActive { get; set; } = true;
}
