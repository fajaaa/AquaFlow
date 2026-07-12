using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;

namespace AquaFlow.Services;

public interface IUserPreferenceService
{
    // Returns the caller's preference row, or defaults (Theme "light", Language "bs",
    // both notification flags true) when no row exists yet - a row is only created on
    // the first update, not lazily on read.
    Task<UserPreferenceResponse> GetByUserIdAsync(int userId);

    // Upsert by UserId - a user has at most one preference row.
    Task<UserPreferenceResponse> UpdateAsync(int userId, UserPreferenceUpdateRequest request);
}
