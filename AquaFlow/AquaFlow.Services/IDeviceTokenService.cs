using AquaFlow.Model.Requests;

namespace AquaFlow.Services;

public interface IDeviceTokenService
{
    // Upsert by (UserId, Token). Used by DeviceTokensController - the caller's user id
    // always comes from the JWT, never from the request.
    Task RegisterAsync(int userId, DeviceTokenRegisterRequest request);

    // Deactivates the caller's own row for this token. No-op (never throws) when the
    // token does not belong to the caller, so the response never reveals whether the
    // token belongs to someone else - same idempotent precedent as logout.
    Task UnregisterAsync(int userId, string token);
}
