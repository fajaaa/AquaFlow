namespace AquaFlow.Model.Requests;

// Self-service account edit: the signed-in user updates only their own contact
// data. Deliberately limited to Email/Phone - role, active state, and password
// are not editable here to avoid privilege escalation. The user id is never part
// of this request; it comes from the JWT on the server.
public class AccountUpdateRequest
{
    public string Email { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;

    // Only meaningful for users without a CustomerProfile (admin/collector) - see User.FirstName/LastName.
    // Null leaves the existing value untouched; callers that don't manage a name (customer/collector apps
    // editing their own CustomerProfile instead) simply omit these.
    public string? FirstName { get; set; }
    public string? LastName { get; set; }
}
