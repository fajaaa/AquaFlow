using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class UserRolePermissionInsertValidator : AbstractValidator<UserRolePermissionInsertRequest>
{
    public UserRolePermissionInsertValidator()
    {
        RuleFor(x => x.UserRoleId).GreaterThan(0);
        RuleFor(x => x.PermissionId).GreaterThan(0);
    }
}
