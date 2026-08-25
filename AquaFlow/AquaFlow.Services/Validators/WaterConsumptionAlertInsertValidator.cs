using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class WaterConsumptionAlertInsertValidator : AbstractValidator<WaterConsumptionAlertInsertRequest>
{
    public WaterConsumptionAlertInsertValidator()
    {
        RuleFor(x => x.CustomerId).GreaterThan(0);
        RuleFor(x => x.AlertType).NotEmpty().MaximumLength(60);
    }
}
