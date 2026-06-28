using AquaFlow.Model.Requests;
using FluentValidation;

namespace AquaFlow.Services.Validators;

public class TariffUpdateValidator : AbstractValidator<TariffUpdateRequest>
{
    public TariffUpdateValidator()
    {
        Include(new TariffInsertValidator());
    }
}
