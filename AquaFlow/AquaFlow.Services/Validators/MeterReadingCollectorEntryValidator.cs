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
        RuleFor(x => x.Note)
            .NotEmpty()
            .When(x => x.IsMeterReplacement)
            .WithMessage("A Note explaining the meter replacement is required when IsMeterReplacement is set.");
        RuleFor(x => x.ReplacedMeterFinalReading)
            .GreaterThanOrEqualTo(0)
            .When(x => x.ReplacedMeterFinalReading.HasValue);
    }
}
