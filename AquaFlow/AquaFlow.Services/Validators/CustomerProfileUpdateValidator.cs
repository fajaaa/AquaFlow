using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class CustomerProfileUpdateValidator : AbstractValidator<CustomerProfileUpdateRequest>
{
    public CustomerProfileUpdateValidator()
    {
        Include(new CustomerProfileInsertValidator());
    }
}
