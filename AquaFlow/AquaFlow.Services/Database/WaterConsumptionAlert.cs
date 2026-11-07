using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace AquaFlow.Services.Database;

public class WaterConsumptionAlert : EntityBase
{
    public int CustomerId { get; set; }
    public CustomerProfile? Customer { get; set; }
    public int WaterMeterId { get; set; }
    public WaterMeter? WaterMeter { get; set; }
    [MaxLength(50)]
    public string AlertType { get; set; } = string.Empty;
    [Column(TypeName = "decimal(18,2)")]
    public decimal MeasuredValue { get; set; }
    // "Usual consumption": average of the last (up to) 3 counting readings BEFORE the measured one,
    // so the anomalous reading never inflates its own reference.
    [Column(TypeName = "decimal(18,2)")]
    public decimal ThresholdValue { get; set; }
    // The model's one-step-ahead forecast (and 95% interval) for the measured reading, trained only on
    // the readings before it; null when there was too little prior history to forecast.
    [Column(TypeName = "decimal(18,3)")]
    public decimal? ExpectedValue { get; set; }
    [Column(TypeName = "decimal(18,3)")]
    public decimal? ExpectedLowerBound { get; set; }
    [Column(TypeName = "decimal(18,3)")]
    public decimal? ExpectedUpperBound { get; set; }
    public string Message { get; set; } = string.Empty;
    public bool IsResolved { get; set; }
    public DateTime? ResolvedAt { get; set; }
}
