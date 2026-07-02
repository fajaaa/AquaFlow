namespace AquaFlow.Model.Requests;

// Self-service account edit: the signed-in user updates only their own contact
// data. Deliberately limited to Email/Phone - role, active state, and password
// are not editable here to avoid privilege escalation. The user id is never part
// of this request; it comes from the JWT on the server.
public class AccountUpdateRequest
{
    public string Email { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
}
