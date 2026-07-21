namespace AquaFlow.Model.Responses;

public class SupportTicketPhotoResponse
{
    // The photo's own id (SupportTicketMessagePhoto.Id).
    public int Id { get; set; }
    public string FileName { get; set; } = string.Empty;
    public string ContentType { get; set; } = string.Empty;
    public long SizeBytes { get; set; }
}
