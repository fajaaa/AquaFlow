using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class WaterMeterRequestPatchValidator : AbstractValidator<WaterMeterRequestPatchRequest>
{
    public WaterMeterRequestPatchValidator()
    {
        RuleFor(x => x.Note).MaximumLength(500);
    }
}
