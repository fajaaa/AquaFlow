using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class UserPatchValidator : AbstractValidator<UserPatchRequest>
{
    public UserPatchValidator()
    {
        RuleFor(x => x.Email).NotEmpty().EmailAddress().MaximumLength(150).When(x => x.Email != null);
        RuleFor(x => x.Password).NotEmpty().When(x => x.Password != null);
        RuleFor(x => x.Phone).MaximumLength(30).When(x => x.Phone != null);
        RuleFor(x => x.UserRoleId).GreaterThan(0).When(x => x.UserRoleId.HasValue);
    }
}
