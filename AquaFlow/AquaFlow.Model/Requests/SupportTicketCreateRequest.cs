namespace AquaFlow.Model.Requests;

public class SupportTicketCreateRequest
{
    public string Subject { get; set; } = string.Empty;
    // Photos are uploaded as IFormFile alongside the request, not carried in the body.
    public string Body { get; set; } = string.Empty;
}
