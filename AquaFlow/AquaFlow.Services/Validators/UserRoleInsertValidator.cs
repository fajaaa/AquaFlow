using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class UserRoleInsertValidator : AbstractValidator<UserRoleInsertRequest>
{
    public UserRoleInsertValidator()
    {
        RuleFor(x => x.Name).NotEmpty().MaximumLength(30);
        RuleFor(x => x.Description).MaximumLength(200);
    }
}
