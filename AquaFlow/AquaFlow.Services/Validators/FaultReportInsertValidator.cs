using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class FaultReportInsertValidator : AbstractValidator<FaultReportInsertRequest>
{
    public FaultReportInsertValidator()
    {
        RuleFor(x => x.ReportedById).GreaterThan(0);
        RuleFor(x => x.CustomerId).GreaterThan(0).When(x => x.CustomerId.HasValue);
        RuleFor(x => x.SettlementId).GreaterThan(0);
        RuleFor(x => x.Street).MaximumLength(200);
        RuleFor(x => x.HouseNumber).MaximumLength(30);
        RuleFor(x => x.Title).NotEmpty().MaximumLength(150);
        RuleFor(x => x.Description).NotEmpty();
        RuleFor(x => x.Status).NotEmpty().MaximumLength(30);
    }
}
