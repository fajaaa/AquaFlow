using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class FaultReportUpdateValidator : AbstractValidator<FaultReportUpdateRequest>
{
    public FaultReportUpdateValidator()
    {
        Include(new FaultReportInsertValidator());
    }
}
