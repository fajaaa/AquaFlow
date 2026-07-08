using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class TariffPatchValidator : AbstractValidator<TariffPatchRequest>
{
    public TariffPatchValidator()
    {
        RuleFor(x => x.Name).NotEmpty().MaximumLength(100).When(x => x.Name != null);
        RuleFor(x => x.Description).NotEmpty().MaximumLength(200).When(x => x.Description != null);
        RuleFor(x => x.PricePerM3).GreaterThanOrEqualTo(0).When(x => x.PricePerM3.HasValue);
    }
}
