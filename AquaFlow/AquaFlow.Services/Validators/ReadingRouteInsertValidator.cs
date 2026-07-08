using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class ReadingRouteInsertValidator : AbstractValidator<ReadingRouteInsertRequest>
{
    public ReadingRouteInsertValidator()
    {
        RuleFor(x => x.Name).NotEmpty().MaximumLength(120);
    }
}
