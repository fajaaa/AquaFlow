using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace AquaFlow.Services.Database;

public class FaultReport : EntityBase
{
    public int ReportedById { get; set; }
    public User? ReportedBy { get; set; }
    public int? WaterMeterId { get; set; }
    public WaterMeter? WaterMeter { get; set; }
    // Nullable: ownership is tracked via ReportedById (the reporting account); CustomerId is
    // informational only (lets the admin table show the customer's name) and stays null for a
    // reporter with no CustomerProfile.
    public int? CustomerId { get; set; }
    public CustomerProfile? Customer { get; set; }
    public int SettlementId { get; set; }
    public Settlement? Settlement { get; set; }
    [MaxLength(200)]
    public string? Street { get; set; }
    [MaxLength(30)]
    public string? HouseNumber { get; set; }
    [MaxLength(150)]
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string? PhotoUrl { get; set; }
    [MaxLength(30)]
    public string Status { get; set; } = "New";
    public int? AssignedCollectorId { get; set; }
    public CollectorProfile? AssignedCollector { get; set; }
    public DateTime? ResolvedAt { get; set; }
    public ICollection<WorkOrder> WorkOrders { get; set; } = new List<WorkOrder>();
    public ICollection<FaultStatusHistory> StatusHistory { get; set; } = new List<FaultStatusHistory>();
    public ICollection<FaultReportPhoto> Photos { get; set; } = new List<FaultReportPhoto>();
}
