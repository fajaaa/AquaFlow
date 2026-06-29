using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class UserRoleUpdateValidator : AbstractValidator<UserRoleUpdateRequest>
{
    public UserRoleUpdateValidator()
    {
        Include(new UserRoleInsertValidator());
    }
}
