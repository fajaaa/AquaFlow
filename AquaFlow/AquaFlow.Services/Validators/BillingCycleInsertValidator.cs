using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class BillingCycleInsertValidator : AbstractValidator<BillingCycleInsertRequest>
{
    public BillingCycleInsertValidator()
    {
        RuleFor(x => x.Name).NotEmpty().MaximumLength(100);
        RuleFor(x => x.PeriodTo).GreaterThanOrEqualTo(x => x.PeriodFrom);
        RuleFor(x => x.Status).Must(status => status is "Open" or "Closed")
            .WithMessage("Status must be 'Open' or 'Closed'.");
    }
}
