namespace AquaFlow.Services;

public interface IPermissionLookupService
{
    Task<IReadOnlyCollection<string>> GetPermissionCodesForRoleAsync(int userRoleId);
}
