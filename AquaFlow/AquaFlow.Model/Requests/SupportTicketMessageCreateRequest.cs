namespace AquaFlow.Model.Requests;

public class SupportTicketMessageCreateRequest
{
    // Photos are uploaded as IFormFile alongside the request, not carried in the body.
    public string Body { get; set; } = string.Empty;
}
