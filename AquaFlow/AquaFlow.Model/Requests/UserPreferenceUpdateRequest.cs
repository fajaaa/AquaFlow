namespace AquaFlow.Model.Requests;

// Self-service preference update: the signed-in user updates their own preferences.
// The user id is never part of this request; it comes from the JWT on the server
// (same trust model as AccountUpdateRequest).
public class UserPreferenceUpdateRequest
{
    public string Theme { get; set; } = string.Empty;
    public string Language { get; set; } = string.Empty;
    public bool ReceiveEmailNotifications { get; set; }
    public bool ReceivePushNotifications { get; set; }
}
