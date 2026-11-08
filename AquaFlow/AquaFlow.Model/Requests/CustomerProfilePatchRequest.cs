namespace AquaFlow.Model.Requests;

// UserId and CustomerCode are immutable after creation, so they are not part of the patch contract.
public class CustomerProfilePatchRequest
{
    public string? FirstName { get; set; }
    public string? LastName { get; set; }
    public int? SettlementId { get; set; }
    public string? Street { get; set; }
    public string? HouseNumber { get; set; }
}
