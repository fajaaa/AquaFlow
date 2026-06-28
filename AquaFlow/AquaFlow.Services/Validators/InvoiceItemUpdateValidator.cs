using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class InvoiceItemUpdateValidator : AbstractValidator<InvoiceItemUpdateRequest>
{
    public InvoiceItemUpdateValidator()
    {
        Include(new InvoiceItemInsertValidator());
    }
}
