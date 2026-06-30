using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class PaymentSettingsPatchValidator : AbstractValidator<PaymentSettingsPatchRequest>
{
    public PaymentSettingsPatchValidator()
    {
        RuleFor(x => x.UpdatedById).GreaterThan(0).When(x => x.UpdatedById.HasValue);
        RuleFor(x => x.CardProvider).NotEmpty().MaximumLength(80).When(x => x.CardProvider != null);
        RuleFor(x => x.PayPalClientId).NotEmpty().MaximumLength(120).When(x => x.PayPalClientId != null);
        RuleFor(x => x.PayPalMerchantEmail).NotEmpty().EmailAddress().MaximumLength(150).When(x => x.PayPalMerchantEmail != null);
    }
}
