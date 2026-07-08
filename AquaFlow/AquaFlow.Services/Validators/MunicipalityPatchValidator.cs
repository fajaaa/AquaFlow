using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class MunicipalityPatchValidator : AbstractValidator<MunicipalityPatchRequest>
{
    public MunicipalityPatchValidator()
    {
        RuleFor(x => x.Name).NotEmpty().MaximumLength(100).When(x => x.Name != null);
        RuleFor(x => x.Code).NotEmpty().MaximumLength(20).When(x => x.Code != null);
        RuleFor(x => x.CityId).GreaterThan(0).When(x => x.CityId.HasValue);
    }
}
