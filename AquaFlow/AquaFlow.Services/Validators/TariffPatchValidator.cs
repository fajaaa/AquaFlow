using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class TariffPatchValidator : AbstractValidator<TariffPatchRequest>
{
    public TariffPatchValidator()
    {
        RuleFor(x => x.Name).NotEmpty().MaximumLength(100).When(x => x.Name != null);
        RuleFor(x => x.CustomerType).NotEmpty().MaximumLength(50).When(x => x.CustomerType != null);
        RuleFor(x => x.PricePerM3).GreaterThanOrEqualTo(0).When(x => x.PricePerM3.HasValue);
        RuleFor(x => x.FixedFee).GreaterThanOrEqualTo(0).When(x => x.FixedFee.HasValue);
        RuleFor(x => x.EffectiveTo).GreaterThanOrEqualTo(x => x.EffectiveFrom)
            .When(x => x.EffectiveFrom.HasValue && x.EffectiveTo.HasValue);
    }
}
