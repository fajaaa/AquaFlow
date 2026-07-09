namespace AquaFlow.Model.Requests;

// Self-service FCM device-token removal. The user id is never part of this request;
// it comes from the JWT on the server (same trust model as DeviceTokenRegisterRequest).
public class DeviceTokenUnregisterRequest
{
    public string Token { get; set; } = string.Empty;
}
