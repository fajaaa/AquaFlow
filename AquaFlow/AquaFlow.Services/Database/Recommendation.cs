using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace AquaFlow.Services.Database;

public class Recommendation : EntityBase
{
    public int CustomerId { get; set; }
    public CustomerProfile? Customer { get; set; }
    public int? WaterMeterId { get; set; }
    public WaterMeter? WaterMeter { get; set; }
    [MaxLength(60)]
    public string Type { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public string Reason { get; set; } = string.Empty;
    public bool IsRead { get; set; }
}
