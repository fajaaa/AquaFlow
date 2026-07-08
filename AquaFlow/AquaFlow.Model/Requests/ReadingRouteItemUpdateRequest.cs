namespace AquaFlow.Model.Requests;

// ReadingRouteId and WaterMeterId are immutable after creation - delete and re-add the item if the
// water meter or route needs to change - so only SortOrder is editable here. Deliberately
// simplified: no reassign logic.
public class ReadingRouteItemUpdateRequest
{
    public int SortOrder { get; set; }
}
