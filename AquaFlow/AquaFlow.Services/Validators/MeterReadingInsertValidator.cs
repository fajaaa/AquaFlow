using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class MeterReadingInsertValidator : AbstractValidator<MeterReadingInsertRequest>
{
    public MeterReadingInsertValidator()
    {
        RuleFor(x => x.WaterMeterId).GreaterThan(0);
        RuleFor(x => x.CollectorId).GreaterThan(0);
        RuleFor(x => x.BillingCycleId).GreaterThan(0).When(x => x.BillingCycleId.HasValue);
        RuleFor(x => x.ReadingValue).GreaterThanOrEqualTo(0);
        RuleFor(x => x.PreviousReadingValue).GreaterThanOrEqualTo(0);
        RuleFor(x => x.ConsumptionM3).GreaterThanOrEqualTo(0);
        RuleFor(x => x.Source).NotEmpty().MaximumLength(30);
        RuleFor(x => x.SyncStatus).NotEmpty().MaximumLength(30);
    }
}
