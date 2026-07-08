using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class SettlementPatchValidator : AbstractValidator<SettlementPatchRequest>
{
    public SettlementPatchValidator()
    {
        RuleFor(x => x.Name).NotEmpty().MaximumLength(100).When(x => x.Name != null);
        RuleFor(x => x.MunicipalityId).GreaterThan(0).When(x => x.MunicipalityId.HasValue);
        RuleFor(x => x.PostalCode).MaximumLength(20).When(x => x.PostalCode != null);
    }
}
