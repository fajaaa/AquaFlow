namespace AquaFlow.Model.SearchObjects;

public class BaseSearchObject
{
    public int? Page { get; set; } = 1;
    public int? PageSize { get; set; } = 10;
    public bool? IncludeTotalCount { get; set; } = false;
}
