using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class UserRolePatchValidator : AbstractValidator<UserRolePatchRequest>
{
    public UserRolePatchValidator()
    {
        RuleFor(x => x.Name).NotEmpty().MaximumLength(30).When(x => x.Name != null);
        RuleFor(x => x.Description).MaximumLength(200).When(x => x.Description != null);
    }
}
