using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class UserInsertValidator : AbstractValidator<UserInsertRequest>
{
    public UserInsertValidator()
    {
        RuleFor(x => x.Email).NotEmpty().EmailAddress().MaximumLength(150);
        RuleFor(x => x.PasswordHash).NotEmpty();
        RuleFor(x => x.Role).NotEmpty().MaximumLength(30);
    }
}
