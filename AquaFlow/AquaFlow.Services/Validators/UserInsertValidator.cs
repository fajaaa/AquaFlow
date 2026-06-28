using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class UserInsertValidator : AbstractValidator<UserInsertRequest>
{
    public UserInsertValidator()
    {
        RuleFor(x => x.Email).NotEmpty().EmailAddress().MaximumLength(150);
        RuleFor(x => x.PasswordHash).NotEmpty();
        RuleFor(x => x.Phone).MaximumLength(30);
        RuleFor(x => x.UserRoleId).GreaterThan(0);
    }
}
