using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class ReadingRoutePatchValidator : AbstractValidator<ReadingRoutePatchRequest>
{
    public ReadingRoutePatchValidator()
    {
        // Patch validates each field only when the caller actually supplied it.
        RuleFor(x => x.Name).NotEmpty().MaximumLength(120).When(x => x.Name != null);
    }
}
