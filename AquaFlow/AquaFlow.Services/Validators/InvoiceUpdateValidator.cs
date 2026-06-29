using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class InvoiceUpdateValidator : AbstractValidator<InvoiceUpdateRequest>
{
    public InvoiceUpdateValidator()
    {
        Include(new InvoiceInsertValidator());
    }
}
