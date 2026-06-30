using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class InvoiceItemPatchValidator : AbstractValidator<InvoiceItemPatchRequest>
{
    public InvoiceItemPatchValidator()
    {
        RuleFor(x => x.InvoiceId).GreaterThan(0).When(x => x.InvoiceId.HasValue);
        RuleFor(x => x.TariffId).GreaterThan(0).When(x => x.TariffId.HasValue);
        RuleFor(x => x.Description).NotEmpty().MaximumLength(200).When(x => x.Description != null);
        RuleFor(x => x.Quantity).GreaterThanOrEqualTo(0).When(x => x.Quantity.HasValue);
        RuleFor(x => x.UnitPrice).GreaterThanOrEqualTo(0).When(x => x.UnitPrice.HasValue);
        RuleFor(x => x.Amount).GreaterThanOrEqualTo(0).When(x => x.Amount.HasValue);
    }
}
