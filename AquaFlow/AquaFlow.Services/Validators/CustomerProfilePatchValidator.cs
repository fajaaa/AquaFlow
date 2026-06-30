using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class CustomerProfilePatchValidator : AbstractValidator<CustomerProfilePatchRequest>
{
    public CustomerProfilePatchValidator()
    {
        RuleFor(x => x.UserId).GreaterThan(0).When(x => x.UserId.HasValue);
        RuleFor(x => x.FirstName).NotEmpty().MaximumLength(80).When(x => x.FirstName != null);
        RuleFor(x => x.LastName).NotEmpty().MaximumLength(80).When(x => x.LastName != null);
        RuleFor(x => x.CustomerCode).NotEmpty().MaximumLength(50).When(x => x.CustomerCode != null);
    }
}
