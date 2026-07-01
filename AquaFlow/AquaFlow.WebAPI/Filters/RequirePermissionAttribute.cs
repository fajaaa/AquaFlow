using AquaFlow.WebAPI.Services.AccessManager;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;

namespace AquaFlow.WebAPI.Filters;

// Granular authorization applied on top of [Authorize]: the request must carry at
// least one of the given permission codes as a Permission claim. Codes are compared
// case-insensitively to match the case-insensitive permission code handling used
// elsewhere (PermissionService uniqueness, seed data).
public class RequirePermissionAttribute : TypeFilterAttribute
{
    public RequirePermissionAttribute(params string[] permissionCodes)
        : base(typeof(RequirePermissionFilter))
    {
        Arguments = new object[] { permissionCodes };
    }

    private class RequirePermissionFilter : IAuthorizationFilter
    {
        private readonly string[] _permissionCodes;

        public RequirePermissionFilter(string[] permissionCodes)
        {
            _permissionCodes = permissionCodes;
        }

        public void OnAuthorization(AuthorizationFilterContext context)
        {
            var user = context.HttpContext.User;
            if (user.Identity?.IsAuthenticated != true)
            {
                context.Result = new UnauthorizedResult();
                return;
            }

            var grantedPermissions = user.Claims
                .Where(claim => claim.Type == ClaimNames.Permission)
                .Select(claim => claim.Value)
                .ToHashSet(StringComparer.OrdinalIgnoreCase);

            if (!_permissionCodes.Any(grantedPermissions.Contains))
            {
                context.Result = new ForbidResult();
            }
        }
    }
}
