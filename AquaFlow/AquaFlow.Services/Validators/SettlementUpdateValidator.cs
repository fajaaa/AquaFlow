using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class SettlementUpdateValidator : AbstractValidator<SettlementUpdateRequest>
{
    public SettlementUpdateValidator()
    {
        Include(new SettlementInsertValidator());
    }
}
