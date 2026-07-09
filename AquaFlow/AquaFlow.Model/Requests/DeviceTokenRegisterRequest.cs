namespace AquaFlow.Model.Requests;

// Self-service FCM device-token registration: the signed-in user registers their own
// device's push token. The user id is never part of this request; it comes from the
// JWT on the server (same trust model as AccountUpdateRequest).
public class DeviceTokenRegisterRequest
{
    public string Token { get; set; } = string.Empty;
    public string Platform { get; set; } = string.Empty;
}
