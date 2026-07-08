using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class BillingCyclePatchValidator : AbstractValidator<BillingCyclePatchRequest>
{
    public BillingCyclePatchValidator()
    {
        RuleFor(x => x.Name).NotEmpty().MaximumLength(100).When(x => x.Name != null);
        RuleFor(x => x.PeriodTo).GreaterThanOrEqualTo(x => x.PeriodFrom!.Value)
            .When(x => x.PeriodFrom.HasValue && x.PeriodTo.HasValue);
        RuleFor(x => x.Status).Must(status => status is "Open" or "Closed")
            .When(x => x.Status != null)
            .WithMessage("Status must be 'Open' or 'Closed'.");
    }
}
