using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class PaymentSettingsUpdateValidator : AbstractValidator<PaymentSettingsUpdateRequest>
{
    public PaymentSettingsUpdateValidator()
    {
        Include(new PaymentSettingsInsertValidator());
    }
}
