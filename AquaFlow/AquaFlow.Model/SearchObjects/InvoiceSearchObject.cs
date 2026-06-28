namespace AquaFlow.Model.SearchObjects;

public class InvoiceSearchObject : BaseSearchObject
{
    public string? InvoiceNumber { get; set; }
    public int? CustomerId { get; set; }
    public int? WaterMeterId { get; set; }
    public string? Status { get; set; }
}
