namespace AquaFlow.Model.Responses;

public class UserPreferenceResponse
{
    public string Theme { get; set; } = string.Empty;
    public string Language { get; set; } = string.Empty;
    public bool ReceiveEmailNotifications { get; set; }
    public bool ReceivePushNotifications { get; set; }
}
