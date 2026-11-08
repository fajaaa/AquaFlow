namespace AquaFlow.Model.Requests;

// Multipart form body of POST /Notifications/with-images; the images travel as form files named
// "images", not in this DTO. CreatedById is never client-supplied - the controller takes it from the
// JWT. The fields are validated by NotificationInsertValidator once converted to a
// NotificationInsertRequest, so the JSON and the multipart create share one set of rules.
public class NotificationWithImagesRequest
{
    public string Title { get; set; } = string.Empty;
    public string Body { get; set; } = string.Empty;
    public string Type { get; set; } = "Info";
    public string Audience { get; set; } = "All";
}
