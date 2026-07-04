using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class AccountUpdateValidator : AbstractValidator<AccountUpdateRequest>
{
    public AccountUpdateValidator()
    {
        RuleFor(x => x.Email).NotEmpty().EmailAddress().MaximumLength(150);
        RuleFor(x => x.Phone).MaximumLength(30).Matches(@"^[0-9+\-\s()]*$")
            .WithMessage("Telefon smije sadržavati samo brojeve i simbole + - ( ).");
    }
}
