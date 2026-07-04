namespace AquaFlow.Model.Requests;

// Self-service password change: the signed-in user proves ownership of the
// account by supplying their current password before a new one is accepted.
// The user id is never part of this request; it comes from the JWT on the server.
public class AccountChangePasswordRequest
{
    public string CurrentPassword { get; set; } = string.Empty;
    public string NewPassword { get; set; } = string.Empty;
}
