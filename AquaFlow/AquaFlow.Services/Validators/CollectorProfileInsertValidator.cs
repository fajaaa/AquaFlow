using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class CollectorProfileInsertValidator : AbstractValidator<CollectorProfileInsertRequest>
{
    public CollectorProfileInsertValidator()
    {
        RuleFor(x => x.UserId).GreaterThan(0);
        // EmployeeCode is server-generated (CollectorProfileService.GenerateEmployeeCodeAsync), not client input.
    }
}
