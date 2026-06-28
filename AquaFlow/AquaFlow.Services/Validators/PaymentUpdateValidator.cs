using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class PaymentUpdateValidator : AbstractValidator<PaymentUpdateRequest>
{
    public PaymentUpdateValidator()
    {
        Include(new PaymentInsertValidator());
    }
}
