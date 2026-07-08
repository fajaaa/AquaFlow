using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class MeterReadingPatchValidator : AbstractValidator<MeterReadingPatchRequest>
{
    public MeterReadingPatchValidator()
    {
        RuleFor(x => x.WaterMeterId).GreaterThan(0).When(x => x.WaterMeterId.HasValue);
        RuleFor(x => x.CollectorId).GreaterThan(0).When(x => x.CollectorId.HasValue);
        RuleFor(x => x.BillingCycleId).GreaterThan(0).When(x => x.BillingCycleId.HasValue);
        RuleFor(x => x.ReadingValue).GreaterThanOrEqualTo(0).When(x => x.ReadingValue.HasValue);
        RuleFor(x => x.PreviousReadingValue).GreaterThanOrEqualTo(0).When(x => x.PreviousReadingValue.HasValue);
        RuleFor(x => x.ConsumptionM3).GreaterThanOrEqualTo(0).When(x => x.ConsumptionM3.HasValue);
        RuleFor(x => x.Source).NotEmpty().MaximumLength(30).When(x => x.Source != null);
        RuleFor(x => x.SyncStatus).NotEmpty().MaximumLength(30).When(x => x.SyncStatus != null);
    }
}
