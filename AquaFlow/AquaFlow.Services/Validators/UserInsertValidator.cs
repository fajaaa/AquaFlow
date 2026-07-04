using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class UserInsertValidator : AbstractValidator<UserInsertRequest>
{
    public UserInsertValidator()
    {
        RuleFor(x => x.Email).NotEmpty().EmailAddress().MaximumLength(150);
        RuleFor(x => x.Password).NotEmpty();
        RuleFor(x => x.Phone).MaximumLength(30).Matches(@"^[0-9+\-\s()]*$")
            .WithMessage("Telefon smije sadržavati samo brojeve i simbole + - ( ).");
        RuleFor(x => x.UserRoleId).GreaterThan(0);
    }
}
