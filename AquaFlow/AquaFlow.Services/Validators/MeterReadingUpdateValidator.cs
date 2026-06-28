using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class MeterReadingUpdateValidator : AbstractValidator<MeterReadingUpdateRequest>
{
    public MeterReadingUpdateValidator()
    {
        Include(new MeterReadingInsertValidator());
    }
}
