namespace AquaFlow.Model.Requests;

// Same immutability as ReadingRouteItemUpdateRequest: only SortOrder can be patched.
public class ReadingRouteItemPatchRequest
{
    public int? SortOrder { get; set; }
}
