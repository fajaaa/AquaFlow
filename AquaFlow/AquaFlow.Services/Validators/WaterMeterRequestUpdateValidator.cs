using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class WaterMeterRequestUpdateValidator : AbstractValidator<WaterMeterRequestUpdateRequest>
{
    public WaterMeterRequestUpdateValidator()
    {
        RuleFor(x => x.SettlementId).GreaterThan(0);
        RuleFor(x => x.Street).NotEmpty().MaximumLength(200);
        RuleFor(x => x.HouseNumber).NotEmpty().MaximumLength(30);
        RuleFor(x => x.Note).MaximumLength(500);
    }
}
