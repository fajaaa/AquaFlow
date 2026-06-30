using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class PermissionPatchValidator : AbstractValidator<PermissionPatchRequest>
{
    public PermissionPatchValidator()
    {
        RuleFor(x => x.Code).NotEmpty().MaximumLength(100).When(x => x.Code != null);
        RuleFor(x => x.Name).NotEmpty().MaximumLength(100).When(x => x.Name != null);
        RuleFor(x => x.Module).MaximumLength(50).When(x => x.Module != null);
        RuleFor(x => x.Description).MaximumLength(200).When(x => x.Description != null);
    }
}
