using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class CompanySettingsInsertValidator : AbstractValidator<CompanySettingsInsertRequest>
{
    public CompanySettingsInsertValidator()
    {
        RuleFor(x => x.CompanyName).NotEmpty().MaximumLength(150);
        RuleFor(x => x.Email).NotEmpty().EmailAddress().MaximumLength(150);
        RuleFor(x => x.DefaultCurrency).NotEmpty().MaximumLength(10);
        RuleFor(x => x.DefaultLanguage).NotEmpty().MaximumLength(10);
    }
}
