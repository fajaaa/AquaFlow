using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

// Mirrors FaultReportInsertValidator minus the Status rule - FaultReportUpdateRequest no longer
// derives from the insert request (status changes only through the state machine), so the rules
// can't be Include()-d anymore.
public class FaultReportUpdateValidator : AbstractValidator<FaultReportUpdateRequest>
{
    public FaultReportUpdateValidator()
    {
        RuleFor(x => x.ReportedById).GreaterThan(0);
        RuleFor(x => x.CustomerId).GreaterThan(0);
        RuleFor(x => x.SettlementId).GreaterThan(0);
        RuleFor(x => x.Title).NotEmpty().MaximumLength(150);
        RuleFor(x => x.Description).NotEmpty();
    }
}
