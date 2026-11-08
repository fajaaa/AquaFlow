using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class WaterMeterPatchValidator : AbstractValidator<WaterMeterPatchRequest>
{
    public WaterMeterPatchValidator()
    {
        RuleFor(x => x.SerialNumber).NotEmpty().MaximumLength(80).When(x => x.SerialNumber != null);
        RuleFor(x => x.SettlementId).GreaterThan(0).When(x => x.SettlementId.HasValue);
        RuleFor(x => x.Street).MaximumLength(200).When(x => x.Street != null);
        RuleFor(x => x.HouseNumber).MaximumLength(30).When(x => x.HouseNumber != null);
        RuleFor(x => x.InitialReading).GreaterThanOrEqualTo(0).When(x => x.InitialReading.HasValue);
    }
}
