using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class CollectorProfileUpdateValidator : AbstractValidator<CollectorProfileUpdateRequest>
{
    public CollectorProfileUpdateValidator()
    {
        Include(new CollectorProfileInsertValidator());
    }
}
