using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class PaymentSettingsInsertValidator : AbstractValidator<PaymentSettingsInsertRequest>
{
    public PaymentSettingsInsertValidator()
    {
        RuleFor(x => x.UpdatedById).GreaterThan(0);
        When(x => x.AllowCardPayments, () =>
        {
            RuleFor(x => x.CardProvider).NotEmpty().MaximumLength(80);
        });
        When(x => x.AllowPayPalPayments, () =>
        {
            RuleFor(x => x.PayPalClientId).NotEmpty().MaximumLength(120);
            RuleFor(x => x.PayPalMerchantEmail).NotEmpty().EmailAddress().MaximumLength(150);
        });
    }
}
