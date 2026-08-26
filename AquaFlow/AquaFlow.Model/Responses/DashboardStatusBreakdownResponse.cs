namespace AquaFlow.Model.Responses;

// One slice of a status-breakdown chart (invoice/fault-report/water-meter-request status counts).
// TotalAmount is only populated where a money total makes sense (invoices); null elsewhere.
public class DashboardStatusBreakdownResponse
{
    public string Status { get; set; } = string.Empty;
    public int Count { get; set; }
    public decimal? TotalAmount { get; set; }
}
