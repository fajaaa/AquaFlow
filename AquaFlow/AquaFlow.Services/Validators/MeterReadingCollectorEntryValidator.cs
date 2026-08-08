using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class MeterReadingCollectorEntryValidator : AbstractValidator<MeterReadingCollectorEntryRequest>
{
    public MeterReadingCollectorEntryValidator()
    {
        RuleFor(x => x.WaterMeterId).GreaterThan(0);
        RuleFor(x => x.ReadingValue).GreaterThanOrEqualTo(0);
        RuleFor(x => x.TariffId).GreaterThan(0);
    }
}
