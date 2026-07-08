using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class CustomerProfileInsertValidator : AbstractValidator<CustomerProfileInsertRequest>
{
    public CustomerProfileInsertValidator()
    {
        RuleFor(x => x.UserId).GreaterThan(0);
        RuleFor(x => x.FirstName).NotEmpty().MaximumLength(80);
        RuleFor(x => x.LastName).NotEmpty().MaximumLength(80);
        // CustomerCode is server-generated (CustomerProfileService.GenerateCustomerCodeAsync), not client input.
        RuleFor(x => x.SettlementId).GreaterThan(0).When(x => x.SettlementId.HasValue);
        RuleFor(x => x.Street).MaximumLength(200).When(x => x.Street != null);
        RuleFor(x => x.HouseNumber).MaximumLength(20).When(x => x.HouseNumber != null);
    }
}
