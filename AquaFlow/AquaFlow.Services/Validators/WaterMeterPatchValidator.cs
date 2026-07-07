using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class WaterMeterPatchValidator : AbstractValidator<WaterMeterPatchRequest>
{
    public WaterMeterPatchValidator()
    {
        RuleFor(x => x.SerialNumber).NotEmpty().MaximumLength(80).When(x => x.SerialNumber != null);
        RuleFor(x => x.CustomerId).GreaterThan(0).When(x => x.CustomerId.HasValue);
        RuleFor(x => x.SettlementId).GreaterThan(0).When(x => x.SettlementId.HasValue);
        RuleFor(x => x.Status).NotEmpty().MaximumLength(30).When(x => x.Status != null);
        RuleFor(x => x.InitialReading).GreaterThanOrEqualTo(0).When(x => x.InitialReading.HasValue);
        RuleFor(x => x.LastReading)
            .GreaterThanOrEqualTo(x => x.InitialReading)
            .When(x => x.LastReading.HasValue && x.InitialReading.HasValue);
    }
}
