using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace AquaFlow.Services.Database;

public class WaterConsumptionAlert : EntityBase
{
    public int CustomerId { get; set; }
    public CustomerProfile? Customer { get; set; }
    public int WaterMeterId { get; set; }
    public WaterMeter? WaterMeter { get; set; }
    [MaxLength(60)]
    public string AlertType { get; set; } = string.Empty;
    [Column(TypeName = "decimal(18,2)")]
    public decimal MeasuredValue { get; set; }
    [Column(TypeName = "decimal(18,2)")]
    public decimal ThresholdValue { get; set; }
    public string Message { get; set; } = string.Empty;
    public bool IsResolved { get; set; }
    public DateTime? ResolvedAt { get; set; }
}
