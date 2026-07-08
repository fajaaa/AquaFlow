using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class BillingCycleUpdateValidator : AbstractValidator<BillingCycleUpdateRequest>
{
    public BillingCycleUpdateValidator()
    {
        Include(new BillingCycleInsertValidator());
    }
}
