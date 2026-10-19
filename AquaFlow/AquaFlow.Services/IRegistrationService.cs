using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;

namespace AquaFlow.Services;

public interface IRegistrationService
{
    // Public customer self-registration as one atomic unit: validates the request, then writes the
    // User (always the Customer role), its CustomerProfile (server-generated CustomerCode) and its
    // UserPreference inside a single DB transaction - if any step throws, nothing is persisted.
    // Returns the new user with FirstName/LastName read back from the created profile.
    Task<UserResponse> RegisterCustomerAsync(UserRegisterRequest request);
}
