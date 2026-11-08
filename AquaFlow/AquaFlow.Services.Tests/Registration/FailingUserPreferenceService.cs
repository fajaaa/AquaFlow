using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;

namespace AquaFlow.Services.Tests.Registration;

// Wraps the real UserPreferenceService and throws right AFTER its UpdateAsync has saved the
// preference row - registration step 3 failing when all three rows are already written inside
// the transaction.
public class FailingUserPreferenceService : IUserPreferenceService
{
    private readonly IUserPreferenceService _inner;

    public FailingUserPreferenceService(IUserPreferenceService inner)
    {
        _inner = inner;
    }

    public Task<UserPreferenceResponse> GetByUserIdAsync(int userId) => _inner.GetByUserIdAsync(userId);

    public async Task<UserPreferenceResponse> UpdateAsync(int userId, UserPreferenceUpdateRequest request)
    {
        await _inner.UpdateAsync(userId, request);
        throw new InvalidOperationException("Simulated failure after the UserPreference was saved.");
    }
}
