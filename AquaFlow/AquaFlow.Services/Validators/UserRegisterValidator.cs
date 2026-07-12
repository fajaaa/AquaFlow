using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class UserRegisterValidator : AbstractValidator<UserRegisterRequest>
{
    public UserRegisterValidator()
    {
        RuleFor(x => x.Email).NotEmpty().EmailAddress().MaximumLength(150);
        RuleFor(x => x.Password).NotEmpty().MinimumLength(6);
        RuleFor(x => x.Phone).MaximumLength(30).Matches(@"^[0-9+\-\s()]*$")
            .WithMessage("Telefon smije sadržavati samo brojeve i simbole + - ( ).");
        RuleFor(x => x.FirstName).NotEmpty().MaximumLength(80);
        RuleFor(x => x.LastName).NotEmpty().MaximumLength(80);
        RuleFor(x => x.Theme)
            .Must(theme => string.IsNullOrEmpty(theme)
                || theme.Equals("light", StringComparison.OrdinalIgnoreCase)
                || theme.Equals("dark", StringComparison.OrdinalIgnoreCase))
            .WithMessage("Theme must be 'light' or 'dark'.");
    }
}
