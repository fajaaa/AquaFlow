using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class UserRolePermissionUpdateValidator : AbstractValidator<UserRolePermissionUpdateRequest>
{
    public UserRolePermissionUpdateValidator()
    {
        Include(new UserRolePermissionInsertValidator());
    }
}
