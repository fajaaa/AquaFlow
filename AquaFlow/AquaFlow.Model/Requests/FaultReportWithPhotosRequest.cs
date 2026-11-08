namespace AquaFlow.Model.Requests;

// Multipart form body of POST /FaultReports/with-photos; the photos travel as form files named
// "photos", not in this DTO. ReportedById/CustomerId/Status are never client-supplied here.
public class FaultReportWithPhotosRequest
{
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public int SettlementId { get; set; }
    public string? Street { get; set; }
    public string? HouseNumber { get; set; }
    public int? WaterMeterId { get; set; }
}
