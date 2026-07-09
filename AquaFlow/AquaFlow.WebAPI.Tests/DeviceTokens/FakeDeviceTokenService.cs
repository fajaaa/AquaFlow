using AquaFlow.Model.Requests;
using AquaFlow.Services;

namespace AquaFlow.WebAPI.Tests.DeviceTokens;

// Hand-written stand-in for IDeviceTokenService so DeviceTokensController tests can drive
// register/unregister without a database. Captures the arguments each call was made with,
// so a test can assert the controller never lets the caller supply their own UserId.
public class FakeDeviceTokenService : IDeviceTokenService
{
    public int? LastRegisterUserId { get; private set; }
    public DeviceTokenRegisterRequest? LastRegisterRequest { get; private set; }
    public int? LastUnregisterUserId { get; private set; }
    public string? LastUnregisterToken { get; private set; }

    public Task RegisterAsync(int userId, DeviceTokenRegisterRequest request)
    {
        LastRegisterUserId = userId;
        LastRegisterRequest = request;
        return Task.CompletedTask;
    }

    public Task UnregisterAsync(int userId, string token)
    {
        LastUnregisterUserId = userId;
        LastUnregisterToken = token;
        return Task.CompletedTask;
    }
}
