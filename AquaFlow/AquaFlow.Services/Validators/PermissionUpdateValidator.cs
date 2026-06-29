using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class PermissionUpdateValidator : AbstractValidator<PermissionUpdateRequest>
{
    public PermissionUpdateValidator()
    {
        Include(new PermissionInsertValidator());
    }
}
