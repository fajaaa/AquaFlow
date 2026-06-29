using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class TariffInsertValidator : AbstractValidator<TariffInsertRequest>
{
    public TariffInsertValidator()
    {
        RuleFor(x => x.Name).NotEmpty().MaximumLength(100);
        RuleFor(x => x.CustomerType).NotEmpty().MaximumLength(50);
        RuleFor(x => x.PricePerM3).GreaterThanOrEqualTo(0);
        RuleFor(x => x.FixedFee).GreaterThanOrEqualTo(0);
    }
}
