using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class UserRolePermissionPatchValidator : AbstractValidator<UserRolePermissionPatchRequest>
{
    public UserRolePermissionPatchValidator()
    {
        RuleFor(x => x.UserRoleId).GreaterThan(0).When(x => x.UserRoleId.HasValue);
        RuleFor(x => x.PermissionId).GreaterThan(0).When(x => x.PermissionId.HasValue);
    }
}
