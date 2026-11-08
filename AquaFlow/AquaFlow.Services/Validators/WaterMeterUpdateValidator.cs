using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class WaterMeterUpdateValidator : AbstractValidator<WaterMeterUpdateRequest>
{
    public WaterMeterUpdateValidator()
    {
        RuleFor(x => x.SerialNumber).NotEmpty().MaximumLength(80);
        RuleFor(x => x.SettlementId).GreaterThan(0);
        RuleFor(x => x.Street).MaximumLength(200);
        RuleFor(x => x.HouseNumber).MaximumLength(30);
        RuleFor(x => x.InitialReading).GreaterThanOrEqualTo(0);
    }
}
