using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class WaterMeterMarkBrokenValidator : AbstractValidator<WaterMeterMarkBrokenRequest>
{
    public WaterMeterMarkBrokenValidator()
    {
        // Capped below ActivityLog.Description's MaxLength(500) to leave headroom for the
        // surrounding text WaterMetersController.MarkBroken composes around the reason.
        RuleFor(x => x.Reason).NotEmpty().MaximumLength(300);
    }
}
