using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class PaymentInsertValidator : AbstractValidator<PaymentInsertRequest>
{
    public PaymentInsertValidator()
    {
        RuleFor(x => x.InvoiceId).GreaterThan(0);
        RuleFor(x => x.CustomerId).GreaterThan(0);
        RuleFor(x => x.Amount).GreaterThan(0);
        RuleFor(x => x.PaymentMethod).NotEmpty().MaximumLength(40);
        RuleFor(x => x.Status).NotEmpty().MaximumLength(30);
    }
}
