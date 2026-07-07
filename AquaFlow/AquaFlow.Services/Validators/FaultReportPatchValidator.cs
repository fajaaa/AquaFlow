using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class FaultReportPatchValidator : AbstractValidator<FaultReportPatchRequest>
{
    public FaultReportPatchValidator()
    {
        RuleFor(x => x.ReportedById).GreaterThan(0).When(x => x.ReportedById.HasValue);
        RuleFor(x => x.CustomerId).GreaterThan(0).When(x => x.CustomerId.HasValue);
        RuleFor(x => x.SettlementId).GreaterThan(0).When(x => x.SettlementId.HasValue);
        RuleFor(x => x.WaterMeterId).GreaterThan(0).When(x => x.WaterMeterId.HasValue);
        RuleFor(x => x.Title).NotEmpty().MaximumLength(150).When(x => x.Title != null);
        RuleFor(x => x.Description).NotEmpty().When(x => x.Description != null);
        RuleFor(x => x.Status).NotEmpty().MaximumLength(30).When(x => x.Status != null);
        RuleFor(x => x.Priority).NotEmpty().MaximumLength(30).When(x => x.Priority != null);
    }
}
