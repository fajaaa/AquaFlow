using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class WaterMeterInsertValidator : AbstractValidator<WaterMeterInsertRequest>
{
    public WaterMeterInsertValidator()
    {
        RuleFor(x => x.SerialNumber).NotEmpty().MaximumLength(80);
        RuleFor(x => x.ServiceLocationId).GreaterThan(0);
        RuleFor(x => x.Status).NotEmpty().MaximumLength(30);
        RuleFor(x => x.InitialReading).GreaterThanOrEqualTo(0);
        RuleFor(x => x.LastReading).GreaterThanOrEqualTo(x => x.InitialReading);
    }
}
