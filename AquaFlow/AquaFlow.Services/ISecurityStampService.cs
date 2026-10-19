using AquaFlow.Services.Database;

namespace AquaFlow.Services;

public interface ISecurityStampService
{
    // True only when the user exists, is active, is not soft-deleted and their current
    // SecurityStamp equals the one carried in the access token. Called for every authenticated
    // request (JwtBearerEvents.OnTokenValidated in Program.cs), so the answer is cached briefly.
    Task<bool> IsValidAsync(int userId, string? securityStamp);

    // Gives a TRACKED user a new stamp. Nothing is written here: the caller's own SaveChangesAsync
    // persists it together with the change that caused it, and the cached stamp is evicted as soon
    // as that save succeeds.
    void Rotate(User user);

    // Rotates (tracked, same deferred save/eviction as Rotate) the stamp of every active user of
    // the role, so their next request gets a 401 and the client refreshes into a token that
    // carries the role's current permissions. Refresh tokens are deliberately left alone.
    Task RotateForRoleAsync(int userRoleId);

    // Same as RotateForRoleAsync, for every active user whose role has this permission assigned.
    Task RotateForPermissionAsync(int permissionId);
}
