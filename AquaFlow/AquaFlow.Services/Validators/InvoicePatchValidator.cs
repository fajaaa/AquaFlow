using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class InvoicePatchValidator : AbstractValidator<InvoicePatchRequest>
{
    public InvoicePatchValidator()
    {
        RuleFor(x => x.InvoiceNumber).NotEmpty().MaximumLength(50).When(x => x.InvoiceNumber != null);
        RuleFor(x => x.CustomerId).GreaterThan(0).When(x => x.CustomerId.HasValue);
        RuleFor(x => x.WaterMeterId).GreaterThan(0).When(x => x.WaterMeterId.HasValue);
        RuleFor(x => x.CurrentReading)
            .GreaterThanOrEqualTo(x => x.PreviousReading)
            .When(x => x.CurrentReading.HasValue && x.PreviousReading.HasValue);
        RuleFor(x => x.ConsumptionM3).GreaterThanOrEqualTo(0).When(x => x.ConsumptionM3.HasValue);
        RuleFor(x => x.TotalAmount).GreaterThanOrEqualTo(0).When(x => x.TotalAmount.HasValue);
        RuleFor(x => x.Status).NotEmpty().MaximumLength(30).When(x => x.Status != null);
        RuleFor(x => x.CreatedById).GreaterThan(0).When(x => x.CreatedById.HasValue);
    }
}
