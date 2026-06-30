using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class PaymentPatchValidator : AbstractValidator<PaymentPatchRequest>
{
    public PaymentPatchValidator()
    {
        RuleFor(x => x.InvoiceId).GreaterThan(0).When(x => x.InvoiceId.HasValue);
        RuleFor(x => x.CustomerId).GreaterThan(0).When(x => x.CustomerId.HasValue);
        RuleFor(x => x.Amount).GreaterThan(0).When(x => x.Amount.HasValue);
        RuleFor(x => x.PaymentMethod).NotEmpty().MaximumLength(40).When(x => x.PaymentMethod != null);
        RuleFor(x => x.Status).NotEmpty().MaximumLength(30).When(x => x.Status != null);
    }
}
