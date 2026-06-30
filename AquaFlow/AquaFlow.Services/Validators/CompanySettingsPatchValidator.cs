using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class CompanySettingsPatchValidator : AbstractValidator<CompanySettingsPatchRequest>
{
    public CompanySettingsPatchValidator()
    {
        RuleFor(x => x.CompanyName).NotEmpty().MaximumLength(150).When(x => x.CompanyName != null);
        RuleFor(x => x.Email).NotEmpty().EmailAddress().MaximumLength(150).When(x => x.Email != null);
        RuleFor(x => x.DefaultCurrency).NotEmpty().MaximumLength(10).When(x => x.DefaultCurrency != null);
        RuleFor(x => x.DefaultLanguage).NotEmpty().MaximumLength(10).When(x => x.DefaultLanguage != null);
    }
}
