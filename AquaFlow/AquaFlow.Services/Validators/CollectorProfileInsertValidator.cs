using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class CollectorProfileInsertValidator : AbstractValidator<CollectorProfileInsertRequest>
{
    public CollectorProfileInsertValidator()
    {
        RuleFor(x => x.UserId).GreaterThan(0);
        RuleFor(x => x.EmployeeCode).NotEmpty().MaximumLength(50);
    }
}
