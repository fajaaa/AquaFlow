using System.ComponentModel.DataAnnotations;

namespace AquaFlow.Services.Database;

public class SupportTicketMessagePhoto : EntityBase
{
    public int SupportTicketMessageId { get; set; }
    public SupportTicketMessage? SupportTicketMessage { get; set; }
    public byte[] Data { get; set; } = Array.Empty<byte>();
    [MaxLength(100)]
    public string ContentType { get; set; } = string.Empty;
    [MaxLength(260)]
    public string FileName { get; set; } = string.Empty;
    public long SizeBytes { get; set; }
}
