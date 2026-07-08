using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace AquaFlow.Services.Database;

public class CollectorProfile : EntityBase
{
    public int UserId { get; set; }
    public User? User { get; set; }
    [MaxLength(50)]
    public string EmployeeCode { get; set; } = string.Empty;
    public int? AssignedAreaId { get; set; }
    public Settlement? AssignedArea { get; set; }
    public ICollection<MeterAssignment> MeterAssignments { get; set; } = new List<MeterAssignment>();
}
