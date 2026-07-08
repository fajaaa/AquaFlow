using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class WaterMeterRequestPatchValidator : AbstractValidator<WaterMeterRequestPatchRequest>
{
    public WaterMeterRequestPatchValidator()
    {
        // Patch validates each field only when the caller actually supplied it.
        RuleFor(x => x.SettlementId).GreaterThan(0).When(x => x.SettlementId.HasValue);
        RuleFor(x => x.Street).NotEmpty().MaximumLength(200).When(x => x.Street != null);
        RuleFor(x => x.HouseNumber).NotEmpty().MaximumLength(30).When(x => x.HouseNumber != null);
        RuleFor(x => x.Note).MaximumLength(500);
    }
}
