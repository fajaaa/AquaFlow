using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class PermissionInsertValidator : AbstractValidator<PermissionInsertRequest>
{
    public PermissionInsertValidator()
    {
        RuleFor(x => x.Code).NotEmpty().MaximumLength(100);
        RuleFor(x => x.Name).NotEmpty().MaximumLength(100);
        RuleFor(x => x.Module).MaximumLength(50);
        RuleFor(x => x.Description).MaximumLength(200);
    }
}
