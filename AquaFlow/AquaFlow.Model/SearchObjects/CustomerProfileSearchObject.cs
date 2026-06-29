namespace AquaFlow.Model.SearchObjects;

public class CustomerProfileSearchObject : BaseSearchObject
{
    public int? UserId { get; set; }
    public string? FirstName { get; set; }
    public string? LastName { get; set; }
    public string? CustomerCode { get; set; }
}
