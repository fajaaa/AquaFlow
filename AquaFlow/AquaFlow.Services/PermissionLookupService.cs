using AquaFlow.Services.Database;
using Microsoft.EntityFrameworkCore;

namespace AquaFlow.Services;

public class PermissionLookupService : IPermissionLookupService
{
    private readonly AquaFlowDbContext _dbContext;

    public PermissionLookupService(AquaFlowDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    // A deactivated role grants nothing: no permission claims at all.
    public async Task<IReadOnlyCollection<string>> GetPermissionCodesForRoleAsync(int userRoleId)
    {
        return await _dbContext.UserRolePermissions
            .Where(assignment => assignment.UserRoleId == userRoleId &&
                assignment.UserRole != null &&
                assignment.UserRole.IsActive &&
                assignment.Permission != null &&
                assignment.Permission.IsActive)
            .Select(assignment => assignment.Permission!.Code)
            .Distinct()
            .ToListAsync();
    }
}
