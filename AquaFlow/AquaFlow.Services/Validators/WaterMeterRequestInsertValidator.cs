using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class WaterMeterRequestInsertValidator : AbstractValidator<WaterMeterRequestInsertRequest>
{
    public WaterMeterRequestInsertValidator()
    {
        RuleFor(x => x.ServiceLocationId).GreaterThan(0);
        RuleFor(x => x.Note).MaximumLength(500);
    }
}
