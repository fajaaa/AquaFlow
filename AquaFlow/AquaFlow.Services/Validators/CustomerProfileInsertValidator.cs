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
        RuleFor(x => x.CustomerCode).NotEmpty().MaximumLength(50);
    }
}
