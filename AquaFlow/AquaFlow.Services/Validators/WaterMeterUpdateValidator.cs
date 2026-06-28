using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class WaterMeterUpdateValidator : AbstractValidator<WaterMeterUpdateRequest>
{
    public WaterMeterUpdateValidator()
    {
        Include(new WaterMeterInsertValidator());
    }
}
