using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class SettlementInsertValidator : AbstractValidator<SettlementInsertRequest>
{
    public SettlementInsertValidator()
    {
        RuleFor(x => x.Name).NotEmpty().MaximumLength(100);
        RuleFor(x => x.MunicipalityId).GreaterThan(0);
        RuleFor(x => x.PostalCode).MaximumLength(20);
    }
}
