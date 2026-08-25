namespace AquaFlow.Model.SearchObjects;

public class RecommendationSearchObject : BaseSearchObject
{
    public int? CustomerId { get; set; }
    public int? WaterMeterId { get; set; }
    public string? Type { get; set; }
    public bool? IsRead { get; set; }
}
