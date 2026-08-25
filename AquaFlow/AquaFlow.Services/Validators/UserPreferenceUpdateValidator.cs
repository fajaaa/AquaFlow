using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class UserPreferenceUpdateValidator : AbstractValidator<UserPreferenceUpdateRequest>
{
    public UserPreferenceUpdateValidator()
    {
        RuleFor(x => x.Theme)
            .NotEmpty()
            .Must(theme => theme.Equals("light", StringComparison.OrdinalIgnoreCase)
                || theme.Equals("dark", StringComparison.OrdinalIgnoreCase))
            .WithMessage("Theme must be 'light' or 'dark'.");
        RuleFor(x => x.Language)
            .NotEmpty()
            .Must(language => language.Equals("bs", StringComparison.OrdinalIgnoreCase)
                || language.Equals("en", StringComparison.OrdinalIgnoreCase))
            .WithMessage("Language must be 'bs' or 'en'.");
    }
}
