using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace AquaFlow.Services.Database;

public class CustomerProfile : EntityBase
{
    public int UserId { get; set; }
    public User? User { get; set; }
    [MaxLength(80)]
    public string FirstName { get; set; } = string.Empty;
    [MaxLength(80)]
    public string LastName { get; set; } = string.Empty;
    [MaxLength(50)]
    public string CustomerCode { get; set; } = string.Empty;
    [MaxLength(10)]
    public string DefaultLanguage { get; set; } = "bs";
    [MaxLength(20)]
    public string Theme { get; set; } = "light";
    // Nullable: a profile is also created for admins/collectors (who only need a name), not just
    // customers with a service address.
    public int? SettlementId { get; set; }
    public Settlement? Settlement { get; set; }
    [MaxLength(200)]
    public string? Street { get; set; }
    // String, not int: house numbers like "12A" or "bb" are common in this address format.
    [MaxLength(20)]
    public string? HouseNumber { get; set; }
    public ICollection<Invoice> Invoices { get; set; } = new List<Invoice>();
    public ICollection<Payment> Payments { get; set; } = new List<Payment>();
    public ICollection<Recommendation> Recommendations { get; set; } = new List<Recommendation>();
    public ICollection<PaymentMethod> PaymentMethods { get; set; } = new List<PaymentMethod>();
    public ICollection<WaterConsumptionAlert> WaterConsumptionAlerts { get; set; } = new List<WaterConsumptionAlert>();
    public ICollection<SupportTicket> SupportTickets { get; set; } = new List<SupportTicket>();
}
