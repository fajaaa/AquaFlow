using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class InvoiceInsertValidator : AbstractValidator<InvoiceInsertRequest>
{
    public InvoiceInsertValidator()
    {
        RuleFor(x => x.InvoiceNumber).NotEmpty().MaximumLength(50);
        RuleFor(x => x.CustomerId).GreaterThan(0);
        RuleFor(x => x.WaterMeterId).GreaterThan(0);
        RuleFor(x => x.CurrentReading).GreaterThanOrEqualTo(x => x.PreviousReading);
        RuleFor(x => x.ConsumptionM3).GreaterThanOrEqualTo(0);
        RuleFor(x => x.TotalAmount).GreaterThanOrEqualTo(0);
        RuleFor(x => x.Status).NotEmpty().MaximumLength(30);
    }
}
