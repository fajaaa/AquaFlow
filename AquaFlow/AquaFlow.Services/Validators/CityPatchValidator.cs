using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class CityPatchValidator : AbstractValidator<CityPatchRequest>
{
    public CityPatchValidator()
    {
        RuleFor(x => x.Name).NotEmpty().MaximumLength(100).When(x => x.Name != null);
        RuleFor(x => x.Code).NotEmpty().MaximumLength(20).When(x => x.Code != null);
    }
}
