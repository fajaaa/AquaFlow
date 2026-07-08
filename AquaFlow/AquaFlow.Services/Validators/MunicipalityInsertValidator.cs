using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class MunicipalityInsertValidator : AbstractValidator<MunicipalityInsertRequest>
{
    public MunicipalityInsertValidator()
    {
        RuleFor(x => x.Name).NotEmpty().MaximumLength(100);
        RuleFor(x => x.Code).NotEmpty().MaximumLength(20);
        RuleFor(x => x.CityId).GreaterThan(0);
    }
}
