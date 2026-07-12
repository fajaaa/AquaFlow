using AquaFlow.Model.Requests;
using AquaFlow.Model.Responses;
using AquaFlow.Services.Database;
using Microsoft.EntityFrameworkCore;

namespace AquaFlow.Services;

public class UserPreferenceService : IUserPreferenceService
{
    private readonly AquaFlowDbContext _dbContext;

    public UserPreferenceService(AquaFlowDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<UserPreferenceResponse> GetByUserIdAsync(int userId)
    {
        var entity = await _dbContext.UserPreferences.FirstOrDefaultAsync(p => p.UserId == userId);
        if (entity is null)
        {
            return new UserPreferenceResponse
            {
                Theme = "light",
                Language = "bs",
                ReceiveEmailNotifications = true,
                ReceivePushNotifications = true
            };
        }

        return ToResponse(entity);
    }

    public async Task<UserPreferenceResponse> UpdateAsync(int userId, UserPreferenceUpdateRequest request)
    {
        var entity = await _dbContext.UserPreferences.FirstOrDefaultAsync(p => p.UserId == userId);
        if (entity is null)
        {
            entity = new UserPreference
            {
                UserId = userId,
                CreatedAt = DateTime.UtcNow
            };
            _dbContext.UserPreferences.Add(entity);
        }

        entity.Theme = request.Theme;
        entity.Language = request.Language;
        entity.ReceiveEmailNotifications = request.ReceiveEmailNotifications;
        entity.ReceivePushNotifications = request.ReceivePushNotifications;
        entity.UpdatedAt = DateTime.UtcNow;

        await _dbContext.SaveChangesAsync();

        return ToResponse(entity);
    }

    private static UserPreferenceResponse ToResponse(UserPreference entity)
    {
        return new UserPreferenceResponse
        {
            Theme = entity.Theme,
            Language = entity.Language,
            ReceiveEmailNotifications = entity.ReceiveEmailNotifications,
            ReceivePushNotifications = entity.ReceivePushNotifications
        };
    }
}
