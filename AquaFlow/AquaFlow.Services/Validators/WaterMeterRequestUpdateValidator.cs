using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class WaterMeterRequestUpdateValidator : AbstractValidator<WaterMeterRequestUpdateRequest>
{
    public WaterMeterRequestUpdateValidator()
    {
        RuleFor(x => x.Note).MaximumLength(500);
    }
}
