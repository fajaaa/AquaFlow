using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class CollectorProfilePatchValidator : AbstractValidator<CollectorProfilePatchRequest>
{
    public CollectorProfilePatchValidator()
    {
        RuleFor(x => x.UserId).GreaterThan(0).When(x => x.UserId.HasValue);
        RuleFor(x => x.AssignedAreaId).GreaterThan(0).When(x => x.AssignedAreaId.HasValue);
        // EmployeeCode is server-generated (CollectorProfileService.GenerateEmployeeCodeAsync), not client input.
    }
}
